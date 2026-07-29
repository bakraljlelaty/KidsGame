import 'dart:convert';

import '../../config/app_config.dart';
import 'data_migrator.dart';
import 'local_store.dart';

/// Loads and saves one versioned JSON document under a fixed [storeKey].
///
/// Every document is stored as `{"v": <schemaVersion>, "data": {...}}`.
/// On load, older versions run through [DataMigrator] before decoding, so
/// model classes only ever see the current schema.
class JsonDocument<T> {
  JsonDocument({
    required this.store,
    required this.storeKey,
    required this.decode,
    required this.encode,
    required this.fallback,
  });

  final LocalStore store;
  final String storeKey;
  final T Function(Map<String, dynamic> json) decode;
  final Map<String, dynamic> Function(T value) encode;
  final T Function() fallback;

  Future<T> load() async {
    final raw = await store.read(storeKey);
    if (raw == null) return fallback();
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final version = envelope['v'] as int? ?? 1;
      var data = (envelope['data'] as Map?)?.cast<String, dynamic>() ?? {};
      if (version < AppConfig.dataSchemaVersion) {
        data = DataMigrator.migrate(storeKey, data, version);
      }
      return decode(data);
    } on FormatException {
      // A corrupt document must never crash the child's app; start fresh.
      return fallback();
    } on TypeError {
      return fallback();
    }
  }

  Future<void> save(T value) async {
    final envelope = <String, dynamic>{
      'v': AppConfig.dataSchemaVersion,
      'data': encode(value),
    };
    await store.write(storeKey, jsonEncode(envelope));
  }

  Future<void> clear() => store.delete(storeKey);
}
