import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key-value abstraction over local storage.
///
/// Everything the app persists goes through this interface, so tests use
/// [InMemoryStore] and a future storage swap (e.g. to a database) only
/// touches this file.
abstract class LocalStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<Set<String>> keys();

  /// Removes every key written by the app. Used by "Delete all child data".
  Future<void> clearAll();
}

class SharedPreferencesStore implements LocalStore {
  SharedPreferencesStore(this._prefs);

  static const String _prefix = 'lww.';

  final SharedPreferences _prefs;

  static Future<SharedPreferencesStore> open() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  @override
  Future<String?> read(String key) async => _prefs.getString('$_prefix$key');

  @override
  Future<void> write(String key, String value) async =>
      _prefs.setString('$_prefix$key', value);

  @override
  Future<void> delete(String key) async => _prefs.remove('$_prefix$key');

  @override
  Future<Set<String>> keys() async => _prefs
      .getKeys()
      .where((k) => k.startsWith(_prefix))
      .map((k) => k.substring(_prefix.length))
      .toSet();

  @override
  Future<void> clearAll() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
  }
}

/// In-memory store for unit and widget tests.
class InMemoryStore implements LocalStore {
  final Map<String, String> _data = {};

  Map<String, String> get snapshot => Map.unmodifiable(_data);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<Set<String>> keys() async => _data.keys.toSet();

  @override
  Future<void> clearAll() async => _data.clear();
}
