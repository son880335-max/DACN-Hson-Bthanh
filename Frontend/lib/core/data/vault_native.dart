import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'vault.dart';

Future<Vault> openVault(String owner) async {
  if(!RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(owner))throw ArgumentError('Invalid account identifier');
  const storage = FlutterSecureStorage(iOptions:IOSOptions(accessibility:KeychainAccessibility.first_unlock_this_device));
  final cipher = AesGcm.with256bits();
  final saved = await storage.read(key: 'vault-key-$owner');
  final secret = saved == null
      ? await cipher.newSecretKey()
      : SecretKey(base64Decode(saved));
  if (saved == null) {
    await storage.write(
      key: 'vault-key-$owner',
      value: base64Encode(await secret.extractBytes()),
    );
  }
  final db = await openDatabase(
    path.join(await getDatabasesPath(), 'relief-$owner.db'),
    version: 1,
    onConfigure: (db) async {
      await db.rawQuery('PRAGMA journal_mode=WAL');
      await db.execute('PRAGMA synchronous=FULL');
    },
    onCreate: (db, _) => db.execute(
      'CREATE TABLE records (id TEXT PRIMARY KEY, nonce BLOB NOT NULL, mac BLOB NOT NULL, ciphertext BLOB NOT NULL)',
    ),
  );
  return _SqlVault(db, cipher, secret, owner);
}

class _SqlVault implements Vault {
  _SqlVault(this.db, this.cipher, this.secret, this.owner);
  final Database db;
  final AesGcm cipher;
  final SecretKey secret;
  final String owner;
  @override
  bool get durable => true;
  Future<SecretBox> _encrypt(String key, Uint8List value) async {
    if (value.length < 65536) {
      return cipher.encrypt(
        value,
        secretKey: secret,
        aad: utf8.encode('$owner:$key'),
      );
    }
    final encoded = await compute(_encryptLarge, {
      'value': value,
      'secret': await secret.extractBytes(),
      'aad': utf8.encode('$owner:$key'),
    });
    return SecretBox(
      encoded['ciphertext']!,
      nonce: encoded['nonce']!,
      mac: Mac(encoded['mac']!),
    );
  }

  @override
  Future<void> write(String key, Uint8List value) async {
    final box = await _encrypt(key, value);
    await db.insert('records', {
      'id': key,
      'nonce': Uint8List.fromList(box.nonce),
      'mac': Uint8List.fromList(box.mac.bytes),
      'ciphertext': Uint8List.fromList(box.cipherText),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<Uint8List?> read(String key) async {
    final rows = await db.query(
      'records',
      where: 'id=?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    if ((row['ciphertext'] as Uint8List).length >= 65536) {
      return compute(_decryptLarge, {
        'value': row['ciphertext'] as Uint8List,
        'nonce': row['nonce'] as Uint8List,
        'mac': row['mac'] as Uint8List,
        'secret': await secret.extractBytes(),
        'aad': utf8.encode('$owner:$key'),
      });
    }
    final value = await cipher.decrypt(
      SecretBox(
        row['ciphertext'] as Uint8List,
        nonce: row['nonce'] as Uint8List,
        mac: Mac(row['mac'] as Uint8List),
      ),
      secretKey: secret,
      aad: utf8.encode('$owner:$key'),
    );
    return Uint8List.fromList(value);
  }

  @override
  Future<List<String>> keys(String prefix) async => (await db.query(
    'records',
    columns: ['id'],
    where: 'substr(id,1,?)=?',
    whereArgs: [prefix.length, prefix],
  )).map((r) => r['id'] as String).toList();
  @override
  Future<void> remove(String key) async {
    await db.delete('records', where: 'id=?', whereArgs: [key]);
  }

  @override
  Future<void> clear() async {
    await db.delete('records');
  }

  @override
  Future<void> commit(
    Map<String, Uint8List> writes,
    List<String> removals,
  ) async {
    final prepared = <Map<String, Object>>[];
    for (final entry in writes.entries) {
      final box = await _encrypt(entry.key, entry.value);
      prepared.add({
        'id': entry.key,
        'nonce': Uint8List.fromList(box.nonce),
        'mac': Uint8List.fromList(box.mac.bytes),
        'ciphertext': Uint8List.fromList(box.cipherText),
      });
    }
    await db.transaction((txn) async {
      for (final key in removals) {
        await txn.delete('records', where: 'id=?', whereArgs: [key]);
      }
      for (final record in prepared) {
        await txn.insert(
          'records',
          record,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> close() => db.close();
}

Future<Map<String, List<int>>> _encryptLarge(
  Map<String, List<int>> message,
) async {
  final box = await AesGcm.with256bits().encrypt(
    message['value']!,
    secretKey: SecretKey(message['secret']!),
    aad: message['aad']!,
  );
  return {
    'ciphertext': box.cipherText,
    'nonce': box.nonce,
    'mac': box.mac.bytes,
  };
}

Future<Uint8List> _decryptLarge(Map<String, List<int>> message) async =>
    Uint8List.fromList(
      await AesGcm.with256bits().decrypt(
        SecretBox(
          message['value']!,
          nonce: message['nonce']!,
          mac: Mac(message['mac']!),
        ),
        secretKey: SecretKey(message['secret']!),
        aad: message['aad']!,
      ),
    );
