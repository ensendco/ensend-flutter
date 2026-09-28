/// Base class for all exceptions thrown by the Ensend SDK.
sealed class EnsendException implements Exception {
  final String message;
  const EnsendException(this.message);

  @override
  String toString() => 'EnsendException: $message';
}

/// Thrown when the HTTP request fails due to a network-level issue (no response
/// received — e.g. no internet, DNS failure, connection refused).
final class EnsendNetworkException extends EnsendException {
  final Object? cause;

  const EnsendNetworkException(super.message, {this.cause});

  @override
  String toString() =>
      'EnsendNetworkException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when the request exceeds the configured [EnsendConfig.timeout].
final class EnsendTimeoutException extends EnsendException {
  const EnsendTimeoutException(super.message);

  @override
  String toString() => 'EnsendTimeoutException: $message';
}

/// Thrown when the SDK cannot parse the API response body.
final class EnsendSerializationException extends EnsendException {
  final Object? cause;

  const EnsendSerializationException(super.message, {this.cause});

  @override
  String toString() =>
      'EnsendSerializationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when required fields on a request model are invalid before the HTTP
/// request is even made (e.g. too many recipients, missing message/template).
final class EnsendValidationException extends EnsendException {
  const EnsendValidationException(super.message);

  @override
  String toString() => 'EnsendValidationException: $message';
}
