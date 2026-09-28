import 'package:meta/meta.dart';

/// The TLS mode used when connecting to Ensend's SMTP relay.
///
/// ```dart
/// final smtp = EnsendSmtpConfig(
///   publicKey: 'pk_...',
///   secret: 'sk_...',
///   encryption: SmtpEncryption.ssl,
/// );
/// print(smtp.port); // 465
/// ```
enum SmtpEncryption {
  /// STARTTLS upgrade on port **587**. Recommended for most use cases.
  starttls,

  /// Implicit TLS on port **465**.
  ssl;

  /// The standard TCP port for this encryption mode.
  int get port => switch (this) {
        SmtpEncryption.starttls => 587,
        SmtpEncryption.ssl => 465,
      };

  /// Whether the connection uses implicit TLS (`true` for [ssl], `false` for
  /// [starttls]).
  bool get useSsl => switch (this) {
        SmtpEncryption.starttls => false,
        SmtpEncryption.ssl => true,
      };
}

/// SMTP connection settings for sending email through Ensend's SMTP relay.
///
/// Use this when you want to integrate Ensend into an existing SMTP-based
/// workflow (e.g. with Dart's `mailer` package) instead of the REST API.
///
/// ```dart
/// // STARTTLS (port 587) — default
/// final smtp = EnsendSmtpConfig(
///   publicKey: 'your_public_key',
///   secret: 'your_project_secret',
/// );
///
/// // Implicit TLS (port 465)
/// final smtp = EnsendSmtpConfig(
///   publicKey: 'your_public_key',
///   secret: 'your_project_secret',
///   encryption: SmtpEncryption.ssl,
/// );
///
/// print(smtp.host);     // smtp.ensend.co
/// print(smtp.port);     // 587
/// print(smtp.username); // your_public_key
/// print(smtp.password); // your_project_secret
/// ```
@immutable
class EnsendSmtpConfig {
  static const String _host = 'smtp.ensend.co';

  /// Your project's public key, used as the SMTP username.
  final String publicKey;

  /// Your project's live or sandbox secret, used as the SMTP password.
  ///
  /// Using a sandbox secret sends messages in sandbox mode (free, not delivered).
  final String secret;

  /// The TLS mode. Defaults to [SmtpEncryption.starttls] (port 587).
  final SmtpEncryption encryption;

  /// The SMTP hostname.
  String get host => _host;

  /// TCP port derived from [encryption].
  int get port => encryption.port;

  /// Whether the connection uses implicit TLS, derived from [encryption].
  bool get useSsl => encryption.useSsl;

  /// The SMTP username — your project's public key.
  String get username => publicKey;

  /// The SMTP password — your project's secret key.
  String get password => secret;

  const EnsendSmtpConfig({
    required this.publicKey,
    required this.secret,
    this.encryption = SmtpEncryption.starttls,
  })  : assert(publicKey != '', 'publicKey must not be empty'),
        assert(secret != '', 'secret must not be empty');

  /// Convenience factory for implicit TLS on port 465.
  factory EnsendSmtpConfig.ssl({
    required String publicKey,
    required String secret,
  }) =>
      EnsendSmtpConfig(
        publicKey: publicKey,
        secret: secret,
        encryption: SmtpEncryption.ssl,
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
      'EnsendSmtpConfig(host: $host, port: $port, encryption: ${encryption.name})';
}
