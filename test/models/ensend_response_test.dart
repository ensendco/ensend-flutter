import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

const _error = EnsendError(message: 'Bad request', statusCode: 400);
const _data = <String, dynamic>{'id': 'msg_1'};

void main() {
  // ---------------------------------------------------------------------------
  // EnsendResponse.success
  // ---------------------------------------------------------------------------
  group('EnsendResponse.success', () {
    const r = EnsendResponse<Map<String, dynamic>>.success(_data);

    test('isSuccess is true', () => expect(r.isSuccess, isTrue));
    test('isError is false', () => expect(r.isError, isFalse));
    test('data is set', () => expect(r.data, _data));
    test('error is null', () => expect(r.error, isNull));

    test('toString contains "success"', () {
      expect(r.toString(), contains('success'));
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendResponse.failure
  // ---------------------------------------------------------------------------
  group('EnsendResponse.failure', () {
    const r = EnsendResponse<Map<String, dynamic>>.failure(_error);

    test('isError is true', () => expect(r.isError, isTrue));
    test('isSuccess is false', () => expect(r.isSuccess, isFalse));
    test('error is set', () => expect(r.error, _error));
    test('data is null', () => expect(r.data, isNull));

    test('toString contains "failure"', () {
      expect(r.toString(), contains('failure'));
    });
  });

  // ---------------------------------------------------------------------------
  // when()
  // ---------------------------------------------------------------------------
  group('EnsendResponse.when', () {
    test('calls onSuccess with data on success', () {
      const r = EnsendResponse<Map<String, dynamic>>.success(_data);
      final out =
          r.when(onSuccess: (d) => 'ok:${d['id']}', onError: (_) => 'err');
      expect(out, 'ok:msg_1');
    });

    test('calls onError with error on failure', () {
      const r = EnsendResponse<Map<String, dynamic>>.failure(_error);
      final out = r.when(
        onSuccess: (_) => 'ok',
        onError: (e) => 'err:${e.statusCode}',
      );
      expect(out, 'err:400');
    });

    test('never calls onError on success', () {
      const r = EnsendResponse<Map<String, dynamic>>.success(_data);
      var errorCalled = false;
      r.when(onSuccess: (_) {}, onError: (_) => errorCalled = true);
      expect(errorCalled, isFalse);
    });

    test('never calls onSuccess on failure', () {
      const r = EnsendResponse<Map<String, dynamic>>.failure(_error);
      var successCalled = false;
      r.when(onSuccess: (_) => successCalled = true, onError: (_) {});
      expect(successCalled, isFalse);
    });

    test('when() return value is the callback result', () {
      const r = EnsendResponse<int>.success(42);
      final doubled = r.when(onSuccess: (n) => n * 2, onError: (_) => 0);
      expect(doubled, 84);
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendResponse with non-Map generic type
  // ---------------------------------------------------------------------------
  group('EnsendResponse<T> generic', () {
    test('works with String data', () {
      const r = EnsendResponse<String>.success('hello');
      expect(r.data, 'hello');
      expect(r.isSuccess, isTrue);
    });

    test('works with int data', () {
      const r = EnsendResponse<int>.success(99);
      expect(r.data, 99);
    });
  });
}
