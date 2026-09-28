/// Contract that all Ensend HTTP transport implementations must satisfy.
///
/// Two built-in adapters ship with the SDK:
/// - [EnsendHttpClient] — backed by `package:http` (default)
/// - [DioEnsendHttpClient] — backed by `package:dio`
///
/// Implement this interface to plug in any custom HTTP layer
/// (proxies, interceptors, test doubles, etc.).
abstract interface class EnsendHttpAdapter {
  /// Sends a POST request to [path] (relative to the configured base URL)
  /// with the JSON-encoded [body].
  ///
  /// Returns the parsed response body as a [Map].
  ///
  /// Throws:
  /// - [EnsendValidationException] — fired before the request by request models
  /// - [EnsendNetworkException] — network-level failure (no response received)
  /// - [EnsendTimeoutException] — request exceeded the configured timeout
  /// - [EnsendSerializationException] — response body could not be parsed
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  );

  /// Releases any underlying connection pool or resources.
  void close();
}
