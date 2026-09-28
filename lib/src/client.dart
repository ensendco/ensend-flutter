import 'package:http/http.dart' as http;

import 'api/send_api.dart';
import 'config.dart';
import 'http/ensend_http_client.dart';
import 'smtp/ensend_smtp_config.dart';

export 'config.dart';
export 'exceptions.dart';
export 'models/broadcast_batch_request.dart';
export 'models/broadcast_mail_request.dart';
export 'models/broadcast_options.dart';
export 'models/broadcast_source.dart';
export 'models/email_attachment.dart';
export 'models/email_recipient.dart';
export 'models/email_sender.dart';
export 'models/email_template.dart';
export 'models/ensend_error.dart';
export 'models/ensend_response.dart';
export 'models/send_mail_options.dart';
export 'models/send_mail_request.dart';
export 'smtp/ensend_smtp_config.dart';

/// The main entry point for the Ensend SDK.
///
/// Create a single instance at app startup and reuse it throughout your
/// application. It manages a persistent HTTP connection pool internally.
///
/// ```dart
/// final ensend = EnsendClient(secret: 'your_project_secret');
///
/// // Send a transactional email
/// final result = await ensend.send.sendMail(
///   SendMailRequest(
///     subject: 'Hello!',
///     sender: EmailSender(address: 'hello@acme.com'),
///     recipients: [EmailRecipient(address: 'user@example.com')],
///     message: '<b>It works!</b>',
///   ),
/// );
/// ```
class EnsendClient {
  /// The configuration used for all API requests.
  final EnsendConfig config;

  /// Access to the Send API — transactional emails and broadcast campaigns.
  final SendApi send;

  final EnsendHttpClient _http;

  EnsendClient._({
    required this.config,
    required EnsendHttpClient httpClient,
  })  : _http = httpClient,
        send = SendApi(httpClient);

  /// Creates an [EnsendClient].
  ///
  /// [secret] — your project's live or sandbox secret key (required).
  /// [baseUrl] — override the API base URL, useful for integration tests.
  /// [timeout] — per-request timeout; defaults to 30 seconds.
  /// [httpClient] — inject a custom [http.Client] for testing or proxying.
  factory EnsendClient({
    required String secret,
    String baseUrl = 'https://api.ensend.co',
    Duration timeout = const Duration(seconds: 30),
    http.Client? httpClient,
  }) {
    final cfg = EnsendConfig(
      secret: secret,
      baseUrl: baseUrl,
      timeout: timeout,
    );
    return EnsendClient._(
      config: cfg,
      httpClient: EnsendHttpClient(cfg, httpClient: httpClient),
    );
  }

  /// Builds an [EnsendSmtpConfig] using the same secret as this client.
  ///
  /// [publicKey] is your project's public key (found alongside the secret in
  /// the Ensend dashboard). Set [ssl] to true to use port 465 (implicit TLS).
  ///
  /// ```dart
  /// final smtp = ensend.smtpConfig(publicKey: 'pk_...', ssl: false);
  /// print(smtp.host); // smtp.ensend.co
  /// ```
  EnsendSmtpConfig smtpConfig({
    required String publicKey,
    bool ssl = false,
  }) {
    return ssl
        ? EnsendSmtpConfig.ssl(publicKey: publicKey, secret: config.secret)
        : EnsendSmtpConfig(publicKey: publicKey, secret: config.secret);
  }

  /// Releases the underlying HTTP connection pool. Call when the client is no
  /// longer needed (e.g. in a server's shutdown hook).
  void close() => _http.close();
}
