import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

import '../helpers/mock_http_client.dart';

const _sender = EmailSender(address: 'hello@acme.com', name: 'Acme');
const _recipient = EmailRecipient(address: 'user@example.com', name: 'Alice');

EnsendClient _makeClient(MockHttpClient mock) =>
    EnsendClient(secret: 'test-secret', httpClient: mock);

void main() {
  setUpAll(registerFallbacks);

  late MockHttpClient mockHttp;
  late EnsendClient client;

  setUp(() {
    mockHttp = MockHttpClient();
    client = _makeClient(mockHttp);
  });

  tearDown(() => client.close());

  group('SendApi.sendMail', () {
    test('returns success response when API returns data envelope', () async {
      whenPost(
        mockHttp,
        successResponse({
          'data': <String, dynamic>{'id': 'msg_123'},
        }),
      );

      final result = await client.send.sendMail(
        const SendMailRequest(
          subject: 'Test',
          sender: _sender,
          recipients: [_recipient],
          message: '<b>Hello</b>',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!['id'], 'msg_123');
    });

    test('returns failure when API returns error body', () async {
      whenPost(
        mockHttp,
        errorResponse(401, {'message': 'Unauthorized', 'statusCode': 401}),
      );

      final result = await client.send.sendMail(
        const SendMailRequest(
          subject: 'Test',
          sender: _sender,
          recipients: [_recipient],
          message: 'Hello',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error!.message, 'Unauthorized');
      expect(result.error!.statusCode, 401);
    });

    test('throws EnsendValidationException before network for invalid request',
        () {
      const invalidRequest = SendMailRequest(
        subject: '',
        sender: _sender,
        recipients: [_recipient],
        message: 'Hello',
      );

      expect(
        () => client.send.sendMail(invalidRequest),
        throwsA(isA<EnsendValidationException>()),
      );
    });

    test('serializes request body correctly', () async {
      whenPost(
        mockHttp,
        successResponse({'data': <String, dynamic>{}}),
      );

      await client.send.sendMail(
        const SendMailRequest(
          subject: 'Hello World',
          sender: _sender,
          recipients: [_recipient],
          message: '<p>Test</p>',
          preheader: 'A preview',
        ),
      );

      final body = capturePostBody(mockHttp);
      expect(body['subject'], 'Hello World');
      expect(body['message'], '<p>Test</p>');
      expect(body['preheader'], 'A preview');
      expect(body['sender']['address'], 'hello@acme.com');
      expect(
        (body['recipients'] as List).first['address'],
        'user@example.com',
      );
    });

    test('throws EnsendNetworkException on network failure', () async {
      whenPostThrows(mockHttp, Exception('No network'));

      expect(
        () => client.send.sendMail(
          const SendMailRequest(
            subject: 'Test',
            sender: _sender,
            recipients: [_recipient],
            message: 'Hello',
          ),
        ),
        throwsA(isA<EnsendNetworkException>()),
      );
    });
  });

  group('SendApi.sendBroadcast', () {
    test('returns success on valid broadcast', () async {
      whenPost(
        mockHttp,
        successResponse(
          {
            'data': <String, dynamic>{'broadcastRef': 'bcast_abc'},
          },
        ),
      );

      final result = await client.send.sendBroadcast(
        const BroadcastMailRequest(
          subject: 'Newsletter',
          sender: _sender,
          recipients: [_recipient],
          message: '<h1>Hello!</h1>',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!['broadcastRef'], 'bcast_abc');
    });

    test('throws validation error for empty recipients and sources', () {
      expect(
        () => client.send.sendBroadcast(
          const BroadcastMailRequest(
            subject: 'Newsletter',
            sender: _sender,
            message: 'Hello',
          ),
        ),
        throwsA(isA<EnsendValidationException>()),
      );
    });
  });

  group('SendApi.sendBroadcastBatch', () {
    test('sends to broadcast endpoint with broadcastRef', () async {
      whenPost(
        mockHttp,
        successResponse({'data': <String, dynamic>{}}),
      );

      await client.send.sendBroadcastBatch(
        const BroadcastBatchRequest(
          broadcastRef: 'bcast_xyz',
          recipients: [_recipient],
        ),
      );

      final body = capturePostBody(mockHttp);
      expect(body['broadcastRef'], 'bcast_xyz');
      expect(
        (body['recipients'] as List).first['address'],
        'user@example.com',
      );
    });

    test('throws validation error for empty broadcastRef', () {
      expect(
        () => client.send.sendBroadcastBatch(
          const BroadcastBatchRequest(
            broadcastRef: '',
            recipients: [_recipient],
          ),
        ),
        throwsA(isA<EnsendValidationException>()),
      );
    });
  });

  group('EnsendResponse', () {
    test('when() calls onSuccess on success', () async {
      whenPost(
        mockHttp,
        successResponse({
          'data': <String, dynamic>{'id': '1'},
        }),
      );

      final result = await client.send.sendMail(
        const SendMailRequest(
          subject: 'Test',
          sender: _sender,
          recipients: [_recipient],
          message: 'Hi',
        ),
      );

      final outcome = result.when(
        onSuccess: (_) => 'success',
        onError: (_) => 'error',
      );
      expect(outcome, 'success');
    });

    test('when() calls onError on failure', () async {
      whenPost(
        mockHttp,
        errorResponse(400, {'message': 'Bad request', 'statusCode': 400}),
      );

      final result = await client.send.sendMail(
        const SendMailRequest(
          subject: 'Test',
          sender: _sender,
          recipients: [_recipient],
          message: 'Hi',
        ),
      );

      final outcome = result.when(
        onSuccess: (_) => 'success',
        onError: (_) => 'error',
      );
      expect(outcome, 'error');
    });
  });
}
