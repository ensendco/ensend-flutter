import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../exceptions.dart';
import '../utils/logger.dart';
import 'ensend_http_adapter.dart';

/// `package:http`-backed transport for the Ensend API.
///
/// This is the default adapter used when you construct [EnsendClient] without
/// specifying an HTTP library. Pass a custom [http.Client] to intercept
/// requests in tests.
///
/// For a `package:dio`-backed alternative see [DioEnsendHttpClient].
class EnsendHttpClient implements EnsendHttpAdapter {
  final EnsendConfig config;
  final EnsendLogger _log;
  final http.Client _client;

  EnsendHttpClient(
    this.config, {
    http.Client? httpClient,
    EnsendLogger? logger,
  })  : _client = httpClient ?? http.Client(),
        _log = logger ?? EnsendLogger(enabled: config.enableLogging);

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${config.baseUrl}$path');
    _log.request('POST', uri.toString(), body);

    late http.Response response;

    try {
      response = await _client
          .post(
            uri,
            headers: config.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(config.timeout);
    } on SocketException catch (e) {
      final msg = 'Network error: unable to reach ${uri.host}';
      _log.error(msg, cause: e);
      throw EnsendNetworkException(msg, cause: e);
    } on TimeoutException {
      final msg =
          'Request to $path timed out after ${config.timeout.inSeconds}s';
      _log.error(msg);
      throw EnsendTimeoutException(msg);
    } on http.ClientException catch (e) {
      final msg = 'HTTP client error: ${e.message}';
      _log.error(msg, cause: e);
      throw EnsendNetworkException(msg, cause: e);
    }

    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    late Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      final msg =
          'Failed to parse API response (status ${response.statusCode})';
      _log.error(msg, cause: e);
      throw EnsendSerializationException(msg, cause: e);
    }

    _log.response(response.statusCode, body);
    return body;
  }

  @override
  void close() => _client.close();
}
