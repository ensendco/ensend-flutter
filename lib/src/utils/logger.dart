import 'dart:convert';
import 'dart:developer' as dev;

/// Internal debug logger for the Ensend SDK.
///
/// When [enabled] is true, request/response details are emitted via
/// [dart:developer]'s `log()`, which surfaces in Flutter DevTools, Dart
/// Observatory, and IDE debug consoles — the same channel as Flutter's
/// `debugPrint`. Output is suppressed in Dart release/profile builds
/// automatically.
///
/// Enable at client construction time:
/// ```dart
/// EnsendClient(secret: '...', enableLogging: true)
/// ```
class EnsendLogger {
  static const String _name = 'EnsendSDK';

  final bool enabled;

  const EnsendLogger({this.enabled = false});

  void request(
    String method,
    String url,
    Map<String, dynamic> body,
  ) {
    if (!enabled) return;
    final sanitized = _sanitize(body);
    _print('→ $method $url\n${_encode(sanitized)}');
  }

  void response(int statusCode, Map<String, dynamic> body) {
    if (!enabled) return;
    _print('← $statusCode\n${_encode(body)}');
  }

  void error(String message, {Object? cause}) {
    if (!enabled) return;
    _print(
      '✗ $message${cause != null ? '\n  cause: $cause' : ''}',
      level: 1000,
    );
  }

  void info(String message) {
    if (!enabled) return;
    _print('ℹ $message');
  }

  void _print(String message, {int level = 0}) {
    // dart:developer log() is the Dart/Flutter equivalent of debugPrint:
    // - appears in Flutter DevTools "Logging" tab
    // - no-op in Dart release mode
    // - throttle-safe (no buffer overflow on rapid calls)
    dev.log(message, name: _name, level: level);
  }

  /// Masks fields that should never appear in logs.
  Map<String, dynamic> _sanitize(Map<String, dynamic> body) {
    final copy = Map<String, dynamic>.from(body);
    // Truncate base64 attachment content — can be megabytes
    if (copy['attachments'] is List) {
      copy['attachments'] = (copy['attachments'] as List).map((a) {
        if (a is Map && a.containsKey('content')) {
          return Map<String, dynamic>.from(a as Map<String, dynamic>)
            ..['content'] = '<base64 truncated>';
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
