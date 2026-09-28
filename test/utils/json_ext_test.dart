import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

void main() {
  // ── getString ───────────────────────────────────────────────────────────────
  group('JsonMapX.getString', () {
    test('returns string value as-is', () {
      expect({'k': 'hello'}.getString('k'), 'hello');
    });

    test('coerces int to string', () {
      expect({'k': 42}.getString('k'), '42');
    });

    test('coerces double to string', () {
      expect({'k': 3.14}.getString('k'), '3.14');
    });

    test('returns fallback when key absent', () {
      expect(<String, dynamic>{}.getString('k', fallback: 'def'), 'def');
    });

    test('returns fallback when value is null', () {
      expect({'k': null}.getString('k', fallback: 'def'), 'def');
    });

    test('default fallback is empty string', () {
      expect(<String, dynamic>{}.getString('missing'), '');
    });
  });

  // ── getStringOrNull ─────────────────────────────────────────────────────────
  group('JsonMapX.getStringOrNull', () {
    test('returns string for existing key', () {
      expect({'k': 'v'}.getStringOrNull('k'), 'v');
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.getStringOrNull('k'), isNull);
    });

    test('returns null when value is null', () {
      expect({'k': null}.getStringOrNull('k'), isNull);
    });

    test('coerces non-string to string', () {
      expect({'k': 99}.getStringOrNull('k'), '99');
    });
  });

  // ── getInt ──────────────────────────────────────────────────────────────────
  group('JsonMapX.getInt', () {
    test('returns int directly', () {
      expect({'k': 7}.getInt('k'), 7);
    });

    test('truncates double', () {
      expect({'k': 7.9}.getInt('k'), 7);
    });

    test('parses string', () {
      expect({'k': '42'}.getInt('k'), 42);
    });

    test('returns fallback for null', () {
      expect({'k': null}.getInt('k', fallback: -1), -1);
    });

    test('returns fallback for absent key', () {
      expect(<String, dynamic>{}.getInt('k', fallback: 99), 99);
    });

    test('returns fallback for unparseable string', () {
      expect({'k': 'abc'}.getInt('k'), 0);
    });

    test('default fallback is 0', () {
      expect(<String, dynamic>{}.getInt('k'), 0);
    });
  });

  // ── getIntOrNull ────────────────────────────────────────────────────────────
  group('JsonMapX.getIntOrNull', () {
    test('returns int directly', () {
      expect({'k': 5}.getIntOrNull('k'), 5);
    });

    test('truncates double', () {
      expect({'k': 5.9}.getIntOrNull('k'), 5);
    });

    test('parses numeric string', () {
      expect({'k': '10'}.getIntOrNull('k'), 10);
    });

    test('returns null for null value', () {
      expect({'k': null}.getIntOrNull('k'), isNull);
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.getIntOrNull('k'), isNull);
    });

    test('returns null for unparseable string', () {
      expect({'k': 'bad'}.getIntOrNull('k'), isNull);
    });
  });

  // ── getDouble ───────────────────────────────────────────────────────────────
  group('JsonMapX.getDouble', () {
    test('returns double directly', () {
      expect({'k': 1.5}.getDouble('k'), 1.5);
    });

    test('promotes int to double', () {
      expect({'k': 3}.getDouble('k'), 3.0);
    });

    test('parses string', () {
      expect({'k': '2.718'}.getDouble('k'), 2.718);
    });

    test('returns fallback for null', () {
      expect({'k': null}.getDouble('k', fallback: -1.0), -1.0);
    });
  });

  // ── getBool ─────────────────────────────────────────────────────────────────
  group('JsonMapX.getBool', () {
    test('returns bool directly', () {
      expect({'k': true}.getBool('k'), isTrue);
      expect({'k': false}.getBool('k'), isFalse);
    });

    test('coerces 1 to true and 0 to false', () {
      expect({'k': 1}.getBool('k'), isTrue);
      expect({'k': 0}.getBool('k'), isFalse);
    });

    test('parses true/false strings case-insensitively', () {
      expect({'k': 'True'}.getBool('k'), isTrue);
      expect({'k': 'FALSE'}.getBool('k'), isFalse);
      expect({'k': '1'}.getBool('k'), isTrue);
      expect({'k': '0'}.getBool('k'), isFalse);
    });

    test('returns fallback for unrecognised string', () {
      expect({'k': 'yes'}.getBool('k'), isFalse);
    });

    test('returns fallback for null', () {
      expect({'k': null}.getBool('k', fallback: true), isTrue);
    });

    test('default fallback is false', () {
      expect(<String, dynamic>{}.getBool('missing'), isFalse);
    });
  });

  // ── getBoolOrNull ───────────────────────────────────────────────────────────
  group('JsonMapX.getBoolOrNull', () {
    test('returns bool directly', () {
      expect({'k': true}.getBoolOrNull('k'), isTrue);
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.getBoolOrNull('k'), isNull);
    });

    test('returns null for unrecognised value', () {
      expect({'k': 'maybe'}.getBoolOrNull('k'), isNull);
    });
  });

  // ── getMap ──────────────────────────────────────────────────────────────────
  group('JsonMapX.getMap', () {
    test('returns nested map', () {
      final m = <String, dynamic>{
        'nested': <String, dynamic>{'a': 1},
      };
      expect(m.getMap('nested'), {'a': 1});
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.getMap('k'), isNull);
    });

    test('returns null when value is not a map', () {
      expect({'k': 'string'}.getMap('k'), isNull);
      expect({'k': 42}.getMap('k'), isNull);
    });

    test('returns null when value is null', () {
      expect({'k': null}.getMap('k'), isNull);
    });
  });

  // ── getList ─────────────────────────────────────────────────────────────────
  group('JsonMapX.getList', () {
    test('returns typed list', () {
      final m = <String, dynamic>{
        'items': ['a', 'b', 'c'],
      };
      expect(m.getList<String>('items'), ['a', 'b', 'c']);
    });

    test('filters elements not of type T', () {
      final m = <String, dynamic>{
        'items': ['a', 1, 'b', 2],
      };
      expect(m.getList<String>('items'), ['a', 'b']);
    });

    test('returns empty list for absent key', () {
      expect(<String, dynamic>{}.getList<String>('k'), isEmpty);
    });

    test('returns empty list when value is not a List', () {
      expect({'k': 'notalist'}.getList<String>('k'), isEmpty);
    });
  });

  // ── getMapList ──────────────────────────────────────────────────────────────
  group('JsonMapX.getMapList', () {
    test('returns list of maps', () {
      final m = <String, dynamic>{
        'items': [
          {'id': 1},
          {'id': 2},
        ],
      };
      final result = m.getMapList('items');
      expect(result, hasLength(2));
      expect(result.first['id'], 1);
    });

    test('filters non-map elements', () {
      final m = <String, dynamic>{
        'items': [
          {'id': 1},
          'bad',
          42,
        ],
      };
      expect(m.getMapList('items'), hasLength(1));
    });

    test('returns empty list for absent key', () {
      expect(<String, dynamic>{}.getMapList('k'), isEmpty);
    });
  });

  // ── hasValue ────────────────────────────────────────────────────────────────
  group('JsonMapX.hasValue', () {
    test('returns true when key has non-null value', () {
      expect({'k': 0}.hasValue('k'), isTrue);
      expect({'k': ''}.hasValue('k'), isTrue);
      expect({'k': false}.hasValue('k'), isTrue);
    });

    test('returns false when key is absent', () {
      expect(<String, dynamic>{}.hasValue('k'), isFalse);
    });

    test('returns false when value is null', () {
      expect({'k': null}.hasValue('k'), isFalse);
    });
  });
}
