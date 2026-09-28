import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../exceptions.dart';

/// Low-level HTTP wrapper used by all API classes.
///
/// Inject a custom [http.Client] in tests to intercept requests without
/// hitting the network.
class EnsendHttpClient {
  final EnsendConfig config;
  final http.Client _client;

  EnsendHttpClient(this.config, {http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${config.baseUrl}$path');

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
      throw EnsendNetworkException(
        'Network error: unable to reach ${uri.host}',
        cause: e,
      );
    } on TimeoutException {
      throw EnsendTimeoutException(
        'Request to $path timed out after ${config.timeout.inSeconds}s',
      );
    } on http.ClientException catch (e) {
      throw EnsendNetworkException('HTTP client error: ${e.message}', cause: e);
    }

    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    late Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw EnsendSerializationException(
        'Failed to parse API response (status ${response.statusCode})',
        cause: e,
      );
    }

    return body;
  }

  void close() => _client.close();
}
