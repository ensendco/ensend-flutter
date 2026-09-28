/// Tests for SendApi's response envelope classification (_Envelope logic):
///   • data envelope   → EnsendResponse.success with nested data
///   • error envelope  → EnsendResponse.failure with EnsendError
///   • unknown envelope → EnsendResponse.success with full body (+ warning)
library;

import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

import '../helpers/mock_http_client.dart';

const _sender = EmailSender(address: 'from@acme.com');
const _recipient = EmailRecipient(address: 'to@example.com');

SendMailRequest get _validRequest => const SendMailRequest(
      subject: 'Test',
      sender: _sender,
      recipients: [_recipient],
      message: 'Hello',
    );

void main() {
  setUpAll(registerFallbacks);

  late MockHttpClient mockHttp;
  late EnsendClient client;

  setUp(() {
    mockHttp = MockHttpClient();
    client = EnsendClient(secret: 'test-secret', httpClient: mockHttp);
  });

  tearDown(() => client.close());

  // ---------------------------------------------------------------------------
  // data envelope
  // ---------------------------------------------------------------------------
  group('data envelope', () {
    test('success → data key extracted into response.data', () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{
          'data': <String, dynamic>{'id': 'msg_99'},
        }),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isSuccess, isTrue);
      expect(r.data!['id'], 'msg_99');
    });

    test('data key present but value is null → whole body returned as success',
        () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{'data': null}),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isSuccess, isTrue);
      // body has no nested map, so the raw body is returned
      expect(r.data, containsPair('data', null));
    });

    test('data key present but value is not a map → whole body returned',
        () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{'data': 'just a string'}),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isSuccess, isTrue);
      expect(r.data!['data'], 'just a string');
    });

    test('empty data map is still a success', () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{'data': <String, dynamic>{}}),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isSuccess, isTrue);
      expect(r.data, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // error envelope
  // ---------------------------------------------------------------------------
  group('error envelope', () {
    test('message key → failure with correct message', () async {
      whenPost(
        mockHttp,
        errorResponse(400, <String, dynamic>{
          'message': 'Invalid subject',
          'statusCode': 400,
        }),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isError, isTrue);
      expect(r.error!.message, 'Invalid subject');
      expect(r.error!.statusCode, 400);
    });

    test('error key without message key → failure', () async {
      whenPost(
        mockHttp,
        errorResponse(401, <String, dynamic>{'error': 'Unauthorized'}),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isError, isTrue);
      expect(r.error!.message, 'Unauthorized');
    });

    test('statusCode coerced from string to int', () async {
      whenPost(
        mockHttp,
        errorResponse(422, <String, dynamic>{
          'message': 'Unprocessable',
          'statusCode': '422',
        }),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isError, isTrue);
      expect(r.error!.statusCode, 422);
    });

    test('missing statusCode falls back to 400', () async {
      whenPost(
        mockHttp,
        errorResponse(400, <String, dynamic>{'message': 'Bad request'}),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isError, isTrue);
      expect(r.error!.statusCode, 400);
    });

    test('both message and error keys → message wins', () async {
      whenPost(
        mockHttp,
        errorResponse(500, <String, dynamic>{
          'message': 'Server error',
          'error': 'Internal',
          'statusCode': 500,
        }),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.error!.message, 'Server error');
    });
  });

  // ---------------------------------------------------------------------------
  // unknown envelope
  // ---------------------------------------------------------------------------
  group('unknown envelope', () {
    test('body with no recognised key → success with full body', () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{'foo': 'bar', 'count': 3}),
      );

      final r = await client.send.sendMail(_validRequest);

      expect(r.isSuccess, isTrue);
      expect(r.data!['foo'], 'bar');
      expect(r.data!['count'], 3);
    });

    test('empty body → success with empty data', () async {
      whenPost(mockHttp, successResponse(<String, dynamic>{}));

      final r = await client.send.sendMail(_validRequest);

      expect(r.isSuccess, isTrue);
      expect(r.data, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendResponse.when integration
  // ---------------------------------------------------------------------------
  group('EnsendResponse.when via SendApi', () {
    test('success result routes to onSuccess', () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{
          'data': <String, dynamic>{'id': '1'},
        }),
      );

      final r = await client.send.sendMail(_validRequest);
      expect(r.when(onSuccess: (_) => 'ok', onError: (_) => 'fail'), 'ok');
    });

    test('error result routes to onError', () async {
      whenPost(
        mockHttp,
        errorResponse(403, <String, dynamic>{
          'message': 'Forbidden',
          'statusCode': 403,
        }),
      );

      final r = await client.send.sendMail(_validRequest);
      expect(
        r.when(onSuccess: (_) => 'ok', onError: (e) => e.statusCode),
        403,
      );
    });
  });
}
