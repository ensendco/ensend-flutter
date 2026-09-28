import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'api/send_api.dart';
import 'config.dart';
import 'dio/ensend_dio_client.dart';
import 'http/ensend_http_adapter.dart';
import 'http/ensend_http_client.dart';
import 'smtp/ensend_smtp_config.dart';
import 'utils/logger.dart';

export 'config.dart';
export 'exceptions.dart';
export 'http/ensend_http_adapter.dart';
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
export 'utils/json_ext.dart';
export 'utils/logger.dart';
export 'utils/type_ext.dart';

/// The main entry point for the Ensend SDK.
///
/// Create a single instance at app startup and reuse it throughout your
/// application. It manages a persistent HTTP connection pool internally.
///
/// **Default (`package:http`):**
/// ```dart
/// final ensend = EnsendClient(secret: 'your_project_secret');
/// ```
///
/// **With Dio (`package:dio`):**
/// ```dart
/// final ensend = EnsendClient.withDio(secret: 'your_project_secret');
///
/// // Or supply a pre-configured Dio with custom interceptors:
/// final dio = Dio()..interceptors.add(LogInterceptor());
/// final ensend = EnsendClient.withDio(secret: 'sk_...', dio: dio);
/// ```
///
/// **Logging** (emits to `dart:developer` — visible in Flutter DevTools):
/// ```dart
/// final ensend = EnsendClient(secret: 'sk_...', enableLogging: true);
/// ```
class EnsendClient {
  /// The resolved configuration for all API requests.
  final EnsendConfig config;

  /// Access to the Send API — transactional emails and broadcast campaigns.
  final SendApi send;

  final EnsendHttpAdapter _adapter;

  EnsendClient._({
    required this.config,
    required EnsendHttpAdapter adapter,
    EnsendLogger? logger,
  })  : _adapter = adapter,
        send = SendApi(adapter, logger: logger);

  /// Creates an [EnsendClient] backed by `package:http`.
  ///
  /// [secret] — your project's live or sandbox secret key (required).
  /// [baseUrl] — override the API base URL; useful in integration tests.
  /// [timeout] — per-request timeout; defaults to 30 seconds.
  /// [enableLogging] — emit levelled, colour-coded logs via `package:logger`.
  ///   Default false.
  /// [logger] — supply a custom [Logger] (e.g. with a [FileOutput] or
  ///   [ProductionFilter]). When omitted a [PrettyPrinter] instance is used.
  /// [httpClient] — inject a custom [http.Client] for testing or proxying.
  factory EnsendClient({
    required String secret,
    String baseUrl = 'https://api.ensend.co',
    Duration timeout = const Duration(seconds: 30),
    bool enableLogging = false,
    Logger? logger,
    http.Client? httpClient,
  }) {
    final cfg = EnsendConfig(
      secret: secret,
      baseUrl: baseUrl,
      timeout: timeout,
      enableLogging: enableLogging,
    );
    final log = EnsendLogger(enabled: enableLogging, logger: logger);
    if (enableLogging) log.info('EnsendClient initialised [http adapter]');
    return EnsendClient._(
      config: cfg,
      adapter: EnsendHttpClient(cfg, httpClient: httpClient, logger: log),
      logger: log,
    );
  }

  /// Creates an [EnsendClient] backed by `package:dio`.
  ///
  /// [secret] — your project's live or sandbox secret key (required).
  /// [baseUrl] — override the API base URL.
  /// [timeout] — per-request timeout; defaults to 30 seconds.
  /// [enableLogging] — emit levelled, colour-coded logs via `package:logger`.
  /// [logger] — supply a custom [Logger] for advanced output (file, remote).
  /// [dio] — supply a pre-configured [Dio] instance to add interceptors,
  ///   certificate pinning, or proxy settings. When omitted a default
  ///   instance is created.
  factory EnsendClient.withDio({
    required String secret,
    String baseUrl = 'https://api.ensend.co',
    Duration timeout = const Duration(seconds: 30),
    bool enableLogging = false,
    Logger? logger,
    Dio? dio,
  }) {
    final cfg = EnsendConfig(
      secret: secret,
      baseUrl: baseUrl,
      timeout: timeout,
      enableLogging: enableLogging,
    );
    final log = EnsendLogger(enabled: enableLogging, logger: logger);
    if (enableLogging) log.info('EnsendClient initialised [dio adapter]');
    return EnsendClient._(
      config: cfg,
      adapter: DioEnsendHttpClient(cfg, dio: dio, logger: log),
      logger: log,
    );
  }

  /// Creates an [EnsendClient] with a custom [EnsendHttpAdapter].
  ///
  /// Use this to plug in a completely custom HTTP transport (e.g. for advanced
  /// proxy configurations or integration testing with a fake server).
  factory EnsendClient.withAdapter({
    required String secret,
    required EnsendHttpAdapter adapter,
    String baseUrl = 'https://api.ensend.co',
    Duration timeout = const Duration(seconds: 30),
    bool enableLogging = false,
  }) {
    final cfg = EnsendConfig(
      secret: secret,
      baseUrl: baseUrl,
      timeout: timeout,
      enableLogging: enableLogging,
    );
    return EnsendClient._(config: cfg, adapter: adapter);
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
    return EnsendSmtpConfig(
      publicKey: publicKey,
      secret: config.secret,
      encryption: ssl ? SmtpEncryption.ssl : SmtpEncryption.starttls,
    );
  }

  /// Releases the underlying HTTP connection pool. Call when the client is no
  /// longer needed (e.g. in a server shutdown hook).
  void close() => _adapter.close();
}
