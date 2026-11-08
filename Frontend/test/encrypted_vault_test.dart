import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:flood_relief_app/core/data/vault_native.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner='d1e41608-5356-4857-a455-7d992c8b3ed0';
  test('real SQLite persists encrypted drafts and atomic receipts; large image encryption survives reopen',()async{
    FlutterSecureStorage.setMockInitialValues({});sqfliteFfiInit();sqlite.databaseFactory=databaseFactoryFfi;
    final directory=await Directory.systemTemp.createTemp('dacn-vault-test-');
    await sqlite.databaseFactory.setDatabasesPath(directory.path);
    final original=Uint8List.fromList(utf8.encode('Private draft: +12025550101'));
    final image=Uint8List.fromList(List.generate(200000,(n)=>n%251));
    var vault=await openVault(owner);
    await vault.write('outbox:operation',original);await vault.write('photo:camera',image);
    await vault.commit({'receipt:operation':original},['outbox:operation']);await vault.close();
    final file=File('${directory.path}${Platform.pathSeparator}relief-$owner.db');
    expect(utf8.decode(await file.readAsBytes(),allowMalformed:true).contains('+12025550101'),false);
    vault=await openVault(owner);expect(await vault.read('outbox:operation'),isNull);
    expect(await vault.read('receipt:operation'),original);expect(await vault.read('photo:camera'),image);await vault.close();
    final database=await databaseFactoryFfi.openDatabase(file.path);
    final row=(await database.query('records',where:'id=?',whereArgs:['receipt:operation'])).single;
    final corrupted=Uint8List.fromList(row['ciphertext'] as Uint8List);corrupted[0]^=1;
    await database.update('records',{'ciphertext':corrupted},where:'id=?',whereArgs:['receipt:operation']);await database.close();
    vault=await openVault(owner);await expectLater(vault.read('receipt:operation'),throwsA(isA<Exception>()));await vault.close();
  });
}
