import 'package:meta/meta.dart';

import '../utils/json_ext.dart';

/// Represents an error returned by the Ensend API.
@immutable
class EnsendError {
  /// Human-readable description of what went wrong.
  final String message;

  /// The HTTP status code associated with this error.
  final int statusCode;

  /// Raw error details from the response body, if any.
  final Map<String, dynamic>? details;

  const EnsendError({
    required this.message,
    required this.statusCode,
    this.details,
  });

  factory EnsendError.fromJson(Map<String, dynamic> json, int statusCode) {
    return EnsendError(
      message: json.getStringOrNull('message') ??
          json.getStringOrNull('error') ??
          'Unknown API error',
      statusCode: statusCode,
      details: json,
    );
  }

  @override
  String toString() => 'EnsendError($statusCode): $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnsendError &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(message, statusCode);
}
