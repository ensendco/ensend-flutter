import 'package:meta/meta.dart';

/// SMTP connection settings for sending email through Ensend's SMTP relay.
///
/// Use this when you want to integrate Ensend into an existing SMTP-based
/// workflow (e.g. with Nodemailer, PHPMailer, or Dart's `mailer` package)
/// instead of the REST API.
///
/// ```dart
/// final smtp = EnsendSmtpConfig(
///   publicKey: 'your_public_key',
///   secret: 'your_project_secret',
/// );
///
/// print(smtp.host);      // smtp.ensend.co
/// print(smtp.port);      // 587
/// print(smtp.username);  // your_public_key
/// print(smtp.password);  // your_project_secret
/// ```
@immutable
class EnsendSmtpConfig {
  static const String _host = 'smtp.ensend.co';

  /// The SMTP hostname.
  String get host => _host;

  /// Your project's public key, used as the SMTP username.
  final String publicKey;

  /// Your project's live or sandbox secret, used as the SMTP password.
  ///
  /// Using a sandbox secret sends messages in sandbox mode (free, not delivered).
  final String secret;

  /// The connection port. Defaults to 587 (STARTTLS).
  /// Use 465 for SSL/TLS.
  final int port;

  /// Whether the connection uses implicit TLS (port 465). When false,
  /// use STARTTLS on port 587.
  final bool useSsl;

  /// The SMTP username — your project's public key.
  String get username => publicKey;

  /// The SMTP password — your project's secret key.
  String get password => secret;

  const EnsendSmtpConfig({
    required this.publicKey,
    required this.secret,
    this.port = 587,
    this.useSsl = false,
  })  : assert(publicKey != '', 'publicKey must not be empty'),
        assert(secret != '', 'secret must not be empty'),
        assert(port == 587 || port == 465,
            'port must be 587 (STARTTLS) or 465 (SSL)');

  /// Returns an SSL config on port 465.
  factory EnsendSmtpConfig.ssl({
    required String publicKey,
    required String secret,
  }) =>
      EnsendSmtpConfig(
        publicKey: publicKey,
        secret: secret,
        port: 465,
        useSsl: true,
      );

  /// Returns a settings map compatible with common SMTP client libraries.
  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'secure': useSsl,
        'auth': {
          'user': username,
          'pass': password,
        },
      };

  @override
  String toString() =>
      'EnsendSmtpConfig(host: $host, port: $port, ssl: $useSsl)';
}
