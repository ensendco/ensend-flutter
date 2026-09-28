import 'package:dio/dio.dart';

import '../config.dart';
import '../exceptions.dart';
import '../utils/logger.dart';
import 'ensend_http_adapter.dart';

/// `package:dio`-backed transport for the Ensend API.
///
/// Use [EnsendClient.withDio] to opt into this adapter. You can supply your own
/// pre-configured [Dio] instance to add interceptors, certificate pinning, or
/// proxy settings without wrapping the client.
///
/// ```dart
/// final dio = Dio()
///   ..interceptors.add(LogInterceptor());
///
/// final client = EnsendClient.withDio(secret: 'sk_...', dio: dio);
/// ```
///
/// Auth headers, base URL, timeout, and `validateStatus` are injected
/// per-request via [Options] so a provided [Dio] instance is never mutated.
class DioEnsendHttpClient implements EnsendHttpAdapter {
  final EnsendConfig config;
  final EnsendLogger _log;
  final Dio _dio;

  DioEnsendHttpClient(
    this.config, {
    Dio? dio,
    EnsendLogger? logger,
  })  : _log = logger ?? EnsendLogger(enabled: config.enableLogging),
        _dio = dio ?? Dio(BaseOptions(baseUrl: config.baseUrl));

  /// Per-request options injected on every call so we never mutate the Dio
  /// instance the user may have pre-configured.
  Options get _requestOptions => Options(
        headers: config.authHeaders,
        // Don't throw on 4xx/5xx — handle status codes ourselves, consistent
        // with the http adapter's behaviour.
        validateStatus: (_) => true,
        sendTimeout: config.timeout,
        receiveTimeout: config.timeout,
      );

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    _log.request('POST', '${config.baseUrl}$path', body);

    late Response<Map<String, dynamic>> response;

    try {
      response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: _requestOptions,
      );
    } on DioException catch (e) {
      _rethrowDioException(e, path);
    }

    final data = response.data;
    if (data == null) {
      const msg = 'Dio returned a null response body';
      _log.error(msg);
      throw const EnsendSerializationException(msg);
    }

    _log.response(response.statusCode ?? 0, data);
    return data;
  }

  Never _rethrowDioException(DioException e, String path) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        final msg =
            'Request to $path timed out after ${config.timeout.inSeconds}s';
        _log.error(msg, cause: e);
        throw EnsendTimeoutException(msg);

      case DioExceptionType.connectionError:
        final msg = 'Network error: ${e.message ?? 'connection failed'}';
        _log.error(msg, cause: e);
        throw EnsendNetworkException(msg, cause: e);

      case DioExceptionType.badCertificate:
        final msg = 'TLS certificate error: ${e.message ?? 'bad certificate'}';
        _log.error(msg, cause: e);
        throw EnsendNetworkException(msg, cause: e);

      case DioExceptionType.cancel:
        const msg = 'Request was cancelled';
        _log.error(msg);
        throw const EnsendNetworkException(msg);

      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final msg = 'Unexpected error: ${e.message ?? e.type.name}';
        _log.error(msg, cause: e);
        throw EnsendNetworkException(msg, cause: e);
    }
  }

  @override
  void close() => _dio.close();
}
