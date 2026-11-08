import 'dart:typed_data';

import 'vault_native.dart'
    if (dart.library.js_interop) 'vault_web.dart'
    as platform;

abstract interface class Vault {
  bool get durable;
  Future<void> write(String key, Uint8List value);
  Future<Uint8List?> read(String key);
  Future<List<String>> keys(String prefix);
  Future<void> remove(String key);
  Future<void> clear();
  Future<void> commit(Map<String, Uint8List> writes, List<String> removals);
  Future<void> close();
}

Future<Vault> openVault(String owner) => platform.openVault(owner);
