import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_wonder_world/config/app_config.dart';
import 'package:little_wonder_world/core/persistence/data_migrator.dart';
import 'package:little_wonder_world/core/persistence/json_document.dart';
import 'package:little_wonder_world/core/persistence/local_store.dart';

void main() {
  group('InMemoryStore', () {
    test('read returns null for a missing key', () async {
      final store = InMemoryStore();
      expect(await store.read('missing'), isNull);
    });

    test('write then read returns the stored value', () async {
      final store = InMemoryStore();
      await store.write('greeting', 'hello');
      expect(await store.read('greeting'), 'hello');
    });

    test('write overwrites an existing value', () async {
      final store = InMemoryStore();
      await store.write('key', 'first');
      await store.write('key', 'second');
      expect(await store.read('key'), 'second');
    });

    test('delete removes a key', () async {
      final store = InMemoryStore();
      await store.write('key', 'value');
      await store.delete('key');
      expect(await store.read('key'), isNull);
      expect(await store.keys(), isEmpty);
    });

    test('keys lists every written key', () async {
      final store = InMemoryStore();
      await store.write('a', '1');
      await store.write('b', '2');
      await store.write('c', '3');
      expect(await store.keys(), {'a', 'b', 'c'});
    });

    test('clearAll wipes everything', () async {
      final store = InMemoryStore();
      await store.write('a', '1');
      await store.write('b', '2');
      await store.clearAll();
      expect(await store.keys(), isEmpty);
      expect(await store.read('a'), isNull);
      expect(store.snapshot, isEmpty);
    });
  });

  group('JsonDocument', () {
    JsonDocument<Map<String, dynamic>> docOn(InMemoryStore store) =>
        JsonDocument<Map<String, dynamic>>(
          store: store,
          storeKey: 'doc',
          decode: (json) => json,
          encode: (value) => value,
          fallback: () => {'fallback': true},
        );

    test('load returns fallback when nothing is stored', () async {
      final doc = docOn(InMemoryStore());
      expect(await doc.load(), {'fallback': true});
    });

    test('save then load round-trips the value', () async {
      final store = InMemoryStore();
      final doc = docOn(store);
      await doc.save({'name': 'milo', 'count': 3});
      expect(await doc.load(), {'name': 'milo', 'count': 3});
    });

    test('saved envelope has the shape {"v": 1, "data": ...}', () async {
      final store = InMemoryStore();
      final doc = docOn(store);
      await doc.save({'name': 'milo'});
      final raw = await store.read('doc');
      expect(raw, isNotNull);
      final envelope = jsonDecode(raw!) as Map<String, dynamic>;
      expect(envelope.keys.toSet(), {'v', 'data'});
      expect(envelope['v'], AppConfig.dataSchemaVersion);
      expect(envelope['v'], 1);
      expect(envelope['data'], {'name': 'milo'});
    });

    test('corrupt JSON returns fallback instead of throwing', () async {
      final store = InMemoryStore();
      await store.write('doc', 'this is {not valid json');
      final doc = docOn(store);
      expect(await doc.load(), {'fallback': true});
    });

    test('valid JSON of the wrong shape returns fallback', () async {
      final store = InMemoryStore();
      await store.write('doc', '[1, 2, 3]');
      final doc = docOn(store);
      expect(await doc.load(), {'fallback': true});
    });

    test('clear deletes the underlying key', () async {
      final store = InMemoryStore();
      final doc = docOn(store);
      await doc.save({'a': 1});
      await doc.clear();
      expect(await store.read('doc'), isNull);
      expect(await doc.load(), {'fallback': true});
    });
  });

  group('DataMigrator', () {
    test('passes data through unchanged at the current schema version', () {
      final data = {'a': 1, 'nested': {'b': 2}};
      final migrated =
          DataMigrator.migrate('progress', data, AppConfig.dataSchemaVersion);
      expect(migrated, same(data));
      expect(migrated, {'a': 1, 'nested': {'b': 2}});
    });
  });
}
