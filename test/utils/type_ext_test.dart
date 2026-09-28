import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

void main() {
  // ── ObjectCoercionX.asString ────────────────────────────────────────────────
  group('ObjectCoercionX.asString', () {
    test('returns string as-is', () {
      expect(('hello' as Object?).asString(), 'hello');
    });

    test('coerces int to string', () {
      expect((42 as Object?).asString(), '42');
    });

    test('coerces double to string', () {
      expect((3.14 as Object?).asString(), '3.14');
    });

    test('returns fallback for null', () {
      expect((null as Object?).asString(fallback: 'default'), 'default');
    });

    test('default fallback is empty string', () {
      expect((null as Object?).asString(), '');
    });
  });

  // ── ObjectCoercionX.asInt ───────────────────────────────────────────────────
  group('ObjectCoercionX.asInt', () {
    test('returns int directly', () {
      expect((7 as Object?).asInt(), 7);
    });

    test('truncates double', () {
      expect((7.9 as Object?).asInt(), 7);
    });

    test('parses numeric string', () {
      expect(('42' as Object?).asInt(), 42);
    });

    test('returns fallback for null', () {
      expect((null as Object?).asInt(fallback: -1), -1);
    });

    test('returns fallback for unparseable string', () {
      expect(('abc' as Object?).asInt(), 0);
    });

    test('default fallback is 0', () {
      expect((null as Object?).asInt(), 0);
    });
  });

  // ── ObjectCoercionX.asDouble ────────────────────────────────────────────────
  group('ObjectCoercionX.asDouble', () {
    test('returns double directly', () {
      expect((1.5 as Object?).asDouble(), 1.5);
    });

    test('promotes int to double', () {
      expect((3 as Object?).asDouble(), 3.0);
    });

    test('parses string', () {
      expect(('2.718' as Object?).asDouble(), 2.718);
    });

    test('returns fallback for null', () {
      expect((null as Object?).asDouble(fallback: -1.0), -1.0);
    });
  });

  // ── ObjectCoercionX.asBool ──────────────────────────────────────────────────
  group('ObjectCoercionX.asBool', () {
    test('returns bool directly', () {
      expect((true as Object?).asBool(), isTrue);
      expect((false as Object?).asBool(), isFalse);
    });

    test('coerces 1 to true and 0 to false', () {
      expect((1 as Object?).asBool(), isTrue);
      expect((0 as Object?).asBool(), isFalse);
    });

    test('parses true/false strings case-insensitively', () {
      expect(('true' as Object?).asBool(), isTrue);
      expect(('FALSE' as Object?).asBool(), isFalse);
      expect(('1' as Object?).asBool(), isTrue);
      expect(('0' as Object?).asBool(), isFalse);
    });

    test('returns fallback for null', () {
      expect((null as Object?).asBool(fallback: true), isTrue);
    });

    test('returns fallback for unrecognised string', () {
      expect(('maybe' as Object?).asBool(), isFalse);
    });
  });

  // ── ObjectCoercionX.asJsonMap ───────────────────────────────────────────────
  group('ObjectCoercionX.asJsonMap', () {
    test('returns Map<String, dynamic> directly', () {
      final map = <String, dynamic>{'a': 1};
      expect((map as Object?).asJsonMap(), {'a': 1});
    });

    test('casts untyped Map', () {
      // Extensions dispatch on the static type; use Object? to keep the map
      // untyped while still going through the extension.
      final Object raw = <Object?, Object?>{'x': 'y'};
      expect(raw.asJsonMap(), {'x': 'y'});
    });

    test('returns null for non-map value', () {
      expect(('string' as Object?).asJsonMap(), isNull);
      expect((42 as Object?).asJsonMap(), isNull);
    });

    test('returns null for null', () {
      expect((null as Object?).asJsonMap(), isNull);
    });
  });

  // ── ObjectCoercionX.asListOf ────────────────────────────────────────────────
  group('ObjectCoercionX.asListOf', () {
    test('returns typed list', () {
      final list = ['a', 'b', 'c'];
      expect((list as Object?).asListOf<String>(), ['a', 'b', 'c']);
    });

    test('filters non-T elements', () {
      final list = ['a', 1, 'b'];
      expect((list as Object?).asListOf<String>(), ['a', 'b']);
    });

    test('returns empty list for non-list value', () {
      expect(('notalist' as Object?).asListOf<String>(), isEmpty);
    });

    test('returns empty list for null', () {
      expect((null as Object?).asListOf<String>(), isEmpty);
    });
  });

  // ── JsonStringX.parseJsonMap ────────────────────────────────────────────────
  group('JsonStringX.parseJsonMap', () {
    test('parses valid JSON object string', () {
      expect('{"a":1,"b":"two"}'.parseJsonMap(), {'a': 1, 'b': 'two'});
    });

    test('throws FormatException for invalid JSON', () {
      expect(() => 'not json'.parseJsonMap(), throwsA(isA<FormatException>()));
    });

    test('throws FormatException for JSON array', () {
      expect(() => '[1,2,3]'.parseJsonMap(), throwsA(isA<FormatException>()));
    });

    test('throws FormatException for JSON primitive', () {
      expect(
        () => '"just a string"'.parseJsonMap(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ── JsonStringX.tryParseJsonMap ─────────────────────────────────────────────
  group('JsonStringX.tryParseJsonMap', () {
    test('parses valid JSON object', () {
      expect('{"x":1}'.tryParseJsonMap(), {'x': 1});
    });

    test('returns null for invalid JSON', () {
      expect('bad'.tryParseJsonMap(), isNull);
    });

    test('returns null for JSON array', () {
      expect('[1,2]'.tryParseJsonMap(), isNull);
    });

    test('returns null for JSON null', () {
      expect('null'.tryParseJsonMap(), isNull);
    });
  });

  // ── JsonStringX.toIntOrNull ─────────────────────────────────────────────────
  group('JsonStringX.toIntOrNull', () {
    test('parses valid integer string', () {
      expect('42'.toIntOrNull(), 42);
    });

    test('returns null for non-integer string', () {
      expect('abc'.toIntOrNull(), isNull);
    });

    test('returns null for float string', () {
      expect('3.14'.toIntOrNull(), isNull);
    });
  });

  // ── JsonStringX.toIntOr ─────────────────────────────────────────────────────
  group('JsonStringX.toIntOr', () {
    test('parses valid integer string', () {
      expect('7'.toIntOr(0), 7);
    });

    test('returns fallback for non-integer string', () {
      expect('bad'.toIntOr(99), 99);
    });
  });

  // ── JsonStringX.toDoubleOrNull ──────────────────────────────────────────────
  group('JsonStringX.toDoubleOrNull', () {
    test('parses valid double string', () {
      expect('3.14'.toDoubleOrNull(), 3.14);
    });

    test('parses integer string as double', () {
      expect('5'.toDoubleOrNull(), 5.0);
    });

    test('returns null for non-numeric string', () {
      expect('xyz'.toDoubleOrNull(), isNull);
    });
  });

  // ── JsonStringX.isTruthy ────────────────────────────────────────────────────
  group('JsonStringX.isTruthy', () {
    test('true for "true" (case-insensitive)', () {
      expect('true'.isTruthy, isTrue);
      expect('TRUE'.isTruthy, isTrue);
    });

    test('true for "1"', () {
      expect('1'.isTruthy, isTrue);
    });

    test('false for anything else', () {
      expect('false'.isTruthy, isFalse);
      expect('yes'.isTruthy, isFalse);
      expect(''.isTruthy, isFalse);
    });
  });
}
