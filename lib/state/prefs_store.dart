import 'package:shared_preferences/shared_preferences.dart';

import 'store.dart';

/// [KeyValueStore] backed by Android SharedPreferences / iOS NSUserDefaults.
/// Reads are synchronous from the in-memory cache that [SharedPreferences]
/// loads once at startup.
class PrefsStore implements KeyValueStore {
  PrefsStore._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsStore> open() async =>
      PrefsStore._(await SharedPreferences.getInstance());

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);
}
