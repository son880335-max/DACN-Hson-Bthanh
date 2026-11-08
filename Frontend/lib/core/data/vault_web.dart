import 'dart:typed_data';

import 'vault.dart';

Future<Vault> openVault(String owner) async => MemoryVault();

class MemoryVault implements Vault {
  final _data = <String, Uint8List>{};
  @override
  bool get durable => false;
  @override
  Future<void> write(String key, Uint8List value) async {
    _data[key] = Uint8List.fromList(value);
  }

  @override
  Future<Uint8List?> read(String key) async => _data[key];
  @override
  Future<List<String>> keys(String prefix) async =>
      _data.keys.where((k) => k.startsWith(prefix)).toList();
  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<void> commit(
    Map<String, Uint8List> writes,
    List<String> removals,
  ) async {
    for (final key in removals) {
      _data.remove(key);
    }
    for (final entry in writes.entries) {
      _data[entry.key] = Uint8List.fromList(entry.value);
    }
  }

  @override
  Future<void> close() async {}
}
