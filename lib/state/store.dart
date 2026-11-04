// Key-value storage seam. The app uses [PrefsStore] (shared_preferences);
// tests use [MemoryStore]. Pure Dart.

abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MemoryStore implements KeyValueStore {
  MemoryStore([Map<String, String>? initial]) : data = {...?initial};

  final Map<String, String> data;

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;

  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Storage keys. Versioned so a future schema change can migrate cleanly.
abstract final class StoreKeys {
  static const account = 'eon.account.v1';
  static const progress = 'eon.progress.v1';
  static const settings = 'eon.settings.v1';
}
