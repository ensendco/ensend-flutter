import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // EnsendError.fromJson
  // ---------------------------------------------------------------------------
  group('EnsendError.fromJson', () {
    test('reads message key', () {
      final err = EnsendError.fromJson(
        <String, dynamic>{'message': 'Not found', 'statusCode': 404},
        404,
      );
      expect(err.message, 'Not found');
      expect(err.statusCode, 404);
    });

    test('falls back to error key when message is absent', () {
      final err = EnsendError.fromJson(
        <String, dynamic>{'error': 'Unauthorized'},
        401,
      );
      expect(err.message, 'Unauthorized');
    });

    test('uses "Unknown API error" when both message and error are absent', () {
      final err = EnsendError.fromJson(<String, dynamic>{}, 500);
      expect(err.message, 'Unknown API error');
    });

    test('stores raw JSON as details', () {
      final json = <String, dynamic>{
        'message': 'Bad request',
        'statusCode': 400,
      };
      final err = EnsendError.fromJson(json, 400);
      expect(err.details, json);
    });

    test('coerces non-string message via toString', () {
      final err = EnsendError.fromJson(
        <String, dynamic>{'message': 42},
        400,
      );
      expect(err.message, '42');
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendError equality
  // ---------------------------------------------------------------------------
  group('EnsendError equality', () {
    const a = EnsendError(message: 'Not found', statusCode: 404);
    const b = EnsendError(message: 'Not found', statusCode: 404);
    const c = EnsendError(message: 'Server error', statusCode: 500);

    test('equal when message and statusCode match', () {
      expect(a, equals(b));
    });

    test('not equal when message differs', () {
      expect(a, isNot(equals(c)));
    });

    test('hashCode matches for equal objects', () {
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes statusCode and message', () {
      expect(a.toString(), contains('404'));
      expect(a.toString(), contains('Not found'));
    });
  });
}
