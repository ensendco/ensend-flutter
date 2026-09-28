import 'dart:async';

import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../helpers/mock_http_client.dart';

const _config = EnsendConfig(secret: 'test-secret');
const _body = <String, dynamic>{'subject': 'Hi'};

void main() {
  setUpAll(registerFallbacks);

  late MockHttpClient mockHttp;
  late EnsendHttpClient adapter;

  setUp(() {
    mockHttp = MockHttpClient();
    adapter = EnsendHttpClient(_config, httpClient: mockHttp);
  });

  tearDown(() => adapter.close());

  // ---------------------------------------------------------------------------
  // Happy path
  // ---------------------------------------------------------------------------
  group('EnsendHttpClient.post — success', () {
    test('returns parsed JSON body on 200', () async {
      whenPost(
        mockHttp,
        successResponse(<String, dynamic>{
          'data': <String, dynamic>{'id': 'msg_1'},
        }),
      );

      final result = await adapter.post('/send/mail', _body);
      expect(result['data'], <String, dynamic>{'id': 'msg_1'});
    });

    test('returns error body on 4xx without throwing', () async {
      whenPost(
        mockHttp,
        errorResponse(401, <String, dynamic>{
          'message': 'Unauthorized',
          'statusCode': 401,
        }),
      );

      final result = await adapter.post('/send/mail', _body);
      expect(result['message'], 'Unauthorized');
      expect(result['statusCode'], 401);
    });

    test('sends Authorization Bearer header', () async {
      late Map<String, String> capturedHeaders;

      when(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedHeaders = inv.namedArguments[#headers] as Map<String, String>;
        return successResponse(<String, dynamic>{'data': <String, dynamic>{}});
      });

      await adapter.post('/send/mail', _body);

      expect(capturedHeaders['Authorization'], 'Bearer test-secret');
      expect(capturedHeaders['Content-Type'], 'application/json');
    });

    test('composes URL from baseUrl + path', () async {
      late Uri capturedUri;

      when(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((inv) async {
        capturedUri = inv.positionalArguments.first as Uri;
        return successResponse(<String, dynamic>{'data': <String, dynamic>{}});
      });

      await adapter.post('/send/mail', _body);
      expect(capturedUri.toString(), 'https://api.ensend.co/send/mail');
    });
  });

  // ---------------------------------------------------------------------------
  // Network errors
  // ---------------------------------------------------------------------------
  group('EnsendHttpClient.post — network errors', () {
    test('throws EnsendTimeoutException when request exceeds timeout',
        () async {
      when(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 10),
          () => http.Response('{}', 200),
        ),
      );

      const shortConfig = EnsendConfig(
        secret: 'test-secret',
        timeout: Duration(milliseconds: 1),
      );
      final shortAdapter = EnsendHttpClient(shortConfig, httpClient: mockHttp);
      addTearDown(shortAdapter.close);

      await expectLater(
        shortAdapter.post('/send/mail', _body),
        throwsA(isA<EnsendTimeoutException>()),
      );
    });

    test('throws EnsendNetworkException on http.ClientException', () {
      whenPostThrows(mockHttp, http.ClientException('Connection refused'));

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendNetworkException>()),
      );
    });

    test('throws EnsendNetworkException on any generic Exception', () {
      whenPostThrows(mockHttp, Exception('Unknown platform error'));

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendNetworkException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization errors
  // ---------------------------------------------------------------------------
  group('EnsendHttpClient.post — serialization errors', () {
    test('throws EnsendSerializationException on non-JSON body', () {
      when(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('<html>Bad Gateway</html>', 502),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendSerializationException>()),
      );
    });

    test('throws EnsendSerializationException when body is a JSON array', () {
      when(
        () => mockHttp.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('[1, 2, 3]', 200));

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendSerializationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendConfig
  // ---------------------------------------------------------------------------
  group('EnsendConfig', () {
    test('authHeaders contains correct keys', () {
      const config = EnsendConfig(secret: 'test-secret');
      final h = config.authHeaders;
      expect(h['Authorization'], 'Bearer test-secret');
      expect(h['Content-Type'], 'application/json');
      expect(h['Accept'], 'application/json');
    });

    test('default baseUrl is api.ensend.co', () {
      expect(_config.baseUrl, 'https://api.ensend.co');
    });

    test('custom baseUrl is respected', () {
      const config =
          EnsendConfig(secret: 'test-secret', baseUrl: 'http://localhost:9000');
      expect(config.baseUrl, 'http://localhost:9000');
    });

    test('default timeout is 30 s', () {
      expect(_config.timeout, const Duration(seconds: 30));
    });

    test('enableLogging defaults to false', () {
      expect(_config.enableLogging, isFalse);
    });
  });
}
