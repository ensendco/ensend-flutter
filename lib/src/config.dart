import 'package:meta/meta.dart';

/// Configuration for the Ensend API client.
@immutable
class EnsendConfig {
  /// Your project's live or sandbox secret key.
  ///
  /// Found at Workspace → Project → Credentials in the Ensend dashboard.
  /// **Never expose this in client-side code.**
  final String secret;

  /// The base URL for all API requests. Defaults to the production endpoint.
  final String baseUrl;

  /// Maximum duration to wait for an API response before timing out.
  final Duration timeout;

  const EnsendConfig({
    required this.secret,
    this.baseUrl = 'https://api.ensend.co',
    this.timeout = const Duration(seconds: 30),
  }) : assert(secret != '', 'secret must not be empty');

  Map<String, String> get authHeaders => {
        'Authorization': 'Bearer $secret',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
