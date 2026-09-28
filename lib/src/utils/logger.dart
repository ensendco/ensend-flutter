import 'dart:convert';

import 'package:logger/logger.dart';

import 'json_ext.dart';
import 'type_ext.dart';

/// Internal debug logger for the Ensend SDK.
///
/// Backed by [package:logger](https://pub.dev/packages/logger) which provides
/// colour-coded, levelled output with pretty-printing. Output respects
/// [Logger]'s active [LogFilter]:
///
/// - The default [DevelopmentFilter] suppresses logs in Dart release/profile
///   builds automatically — same safety guarantee as Flutter's `kDebugMode`.
/// - Pass a custom [Logger] (e.g. with [ProductionFilter]) to keep logs in
///   release builds when debugging production issues.
///
/// Enable at client construction time:
/// ```dart
/// EnsendClient(secret: '...', enableLogging: true)
/// ```
///
/// Bring your own [Logger] for custom printers, filters, or outputs:
/// ```dart
/// EnsendClient(
///   secret: '...',
///   enableLogging: true,
///   logger: Logger(
///     printer: SimplePrinter(),
///     output: FileOutput(file: logFile),
///   ),
/// )
/// ```
class EnsendLogger {
  static const String _tag = 'EnsendSDK';

  /// Whether logging is active. When false every log method is a no-op.
  final bool enabled;
  final Logger _logger;

  EnsendLogger({this.enabled = false, Logger? logger})
      : _logger = logger ?? _buildDefaultLogger();

  static Logger _buildDefaultLogger() => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 6,
          lineLength: 100,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  /// Logs an outgoing HTTP request at **debug** level.
  void request(String method, String url, Map<String, dynamic> body) {
    if (!enabled) return;
    _logger.d('[$_tag] → $method $url\n${_encode(_sanitize(body))}');
  }

  /// Logs a received HTTP response at **info** level.
  void response(int statusCode, Map<String, dynamic> body) {
    if (!enabled) return;
    _logger.i('[$_tag] ← $statusCode\n${_encode(body)}');
  }

  /// Logs a network or serialization error at **error** level.
  void error(String message, {Object? cause}) {
    if (!enabled) return;
    _logger.e('[$_tag] $message', error: cause);
  }

  /// Logs a general informational message at **info** level.
  void info(String message) {
    if (!enabled) return;
    _logger.i('[$_tag] $message');
  }

  /// Logs a warning (e.g. deprecated usage, fallback taken) at **warning** level.
  void warning(String message) {
    if (!enabled) return;
    _logger.w('[$_tag] $message');
  }

  /// Masks fields that must not appear in logs (e.g. large base64 blobs).
  Map<String, dynamic> _sanitize(Map<String, dynamic> body) {
    final copy = Map<String, dynamic>.from(body);
    final attachments = copy.getList<Object>('attachments');
    if (attachments.isNotEmpty) {
      copy['attachments'] = attachments.map((a) {
        final map = a.asJsonMap();
        if (map != null && map.containsKey('content')) {
          return {...map, 'content': '<base64 — truncated>'};
        }
        return a;
      }).toList();
    }
    return copy;
  }

  String _encode(Map<String, dynamic> body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}
