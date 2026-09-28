import 'package:dio/dio.dart';
import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks & helpers
// ---------------------------------------------------------------------------

class MockDio extends Mock implements Dio {}

class FakeRequestOptions extends Fake implements RequestOptions {}

RequestOptions _opts(String path) => RequestOptions(path: path);

Response<Map<String, dynamic>> _dioResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
  String path = '/send/mail',
}) =>
    Response<Map<String, dynamic>>(
      requestOptions: _opts(path),
      statusCode: statusCode,
      data: data,
    );

DioException _dioException(
  DioExceptionType type, {
  String? message,
  String path = '/send/mail',
}) =>
    DioException(
      requestOptions: _opts(path),
      type: type,
      message: message,
    );

const _config = EnsendConfig(secret: 'sk_test');
const _body = <String, dynamic>{'subject': 'Hi'};

/// Stubs mockDio.post to return [response].
void _whenPost(MockDio dio, Response<Map<String, dynamic>> response) {
  when(
    () => dio.post<Map<String, dynamic>>(
      any(),
      data: any(named: 'data'),
      options: any(named: 'options'),
    ),
  ).thenAnswer((_) async => response);
}

/// Stubs mockDio.post to throw [exception].
void _whenPostThrows(MockDio dio, DioException exception) {
  when(
    () => dio.post<Map<String, dynamic>>(
      any(),
      data: any(named: 'data'),
      options: any(named: 'options'),
    ),
  ).thenThrow(exception);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(Options());
  });

  late MockDio mockDio;
  late DioEnsendHttpClient adapter;

  setUp(() {
    mockDio = MockDio();
    adapter = DioEnsendHttpClient(_config, dio: mockDio);
  });

  tearDown(() => adapter.close());

  group('DioEnsendHttpClient.post', () {
    test('returns parsed response body on success', () async {
      _whenPost(
        mockDio,
        _dioResponse({
          'data': <String, dynamic>{'id': 'msg_1'},
        }),
      );

      final result = await adapter.post('/send/mail', _body);
      expect(result['data'], {'id': 'msg_1'});
    });

    test('returns error body on 4xx without throwing', () async {
      _whenPost(
        mockDio,
        _dioResponse(
          {'message': 'Unauthorized', 'statusCode': 401},
          statusCode: 401,
        ),
      );

      final result = await adapter.post('/send/mail', _body);
      expect(result['message'], 'Unauthorized');
    });

    test('throws EnsendTimeoutException on connection timeout', () {
      _whenPostThrows(
        mockDio,
        _dioException(DioExceptionType.connectionTimeout),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendTimeoutException>()),
      );
    });

    test('throws EnsendTimeoutException on receive timeout', () {
      _whenPostThrows(
        mockDio,
        _dioException(DioExceptionType.receiveTimeout),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendTimeoutException>()),
      );
    });

    test('throws EnsendTimeoutException on send timeout', () {
      _whenPostThrows(
        mockDio,
        _dioException(DioExceptionType.sendTimeout),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendTimeoutException>()),
      );
    });

    test('throws EnsendNetworkException on connection error', () {
      _whenPostThrows(
        mockDio,
        _dioException(DioExceptionType.connectionError),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendNetworkException>()),
      );
    });

    test('throws EnsendNetworkException on bad certificate', () {
      _whenPostThrows(
        mockDio,
        _dioException(DioExceptionType.badCertificate),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendNetworkException>()),
      );
    });

    test('throws EnsendNetworkException on cancelled request', () {
      _whenPostThrows(
        mockDio,
        _dioException(DioExceptionType.cancel),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendNetworkException>()),
      );
    });

    test('throws EnsendSerializationException when Dio data is null', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _opts('/send/mail'),
          statusCode: 200,
        ),
      );

      expect(
        () => adapter.post('/send/mail', _body),
        throwsA(isA<EnsendSerializationException>()),
      );
    });

    test('injects auth headers per-request', () async {
      late Options capturedOptions;

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: captureAny(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedOptions = invocation.namedArguments[#options] as Options;
        return _dioResponse({'data': <String, dynamic>{}});
      });

      await adapter.post('/send/mail', _body);

      expect(
        capturedOptions.headers!['Authorization'],
        'Bearer sk_test',
      );
      expect(capturedOptions.validateStatus!.call(400), isTrue);
    });
  });

  group('EnsendClient.withDio factory', () {
    test('creates client with Dio adapter', () {
      final client = EnsendClient.withDio(secret: 'sk_test');
      expect(client.config.secret, 'sk_test');
      expect(client.config.baseUrl, 'https://api.ensend.co');
      client.close();
    });

    test('accepts enableLogging flag', () {
      final client = EnsendClient.withDio(
        secret: 'sk_test',
        enableLogging: true,
      );
      expect(client.config.enableLogging, isTrue);
      client.close();
    });

    test('accepts custom baseUrl', () {
      final client = EnsendClient.withDio(
        secret: 'sk_test',
        baseUrl: 'http://localhost:8080',
      );
      expect(client.config.baseUrl, 'http://localhost:8080');
      client.close();
    });

    test('exposes send API', () {
      final client = EnsendClient.withDio(secret: 'sk_test');
      expect(client.send, isNotNull);
      client.close();
    });
  });

  group('EnsendClient.withAdapter factory', () {
    test('uses provided adapter directly', () async {
      final mock = _MockAdapter();
      when(() => mock.post(any(), any())).thenAnswer(
        (_) async => {'data': <String, dynamic>{}},
      );
      when(mock.close).thenReturn(null);

      final client = EnsendClient.withAdapter(
        secret: 'sk_test',
        adapter: mock,
      );
      expect(client, isNotNull);
      client.close();
    });
  });
}

class _MockAdapter extends Mock implements EnsendHttpAdapter {}
