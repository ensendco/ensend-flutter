import 'dart:convert';

/// Safe type-coercion helpers for any [Object?] value.
///
/// Useful when the source is typed as `dynamic` and you need a specific
/// primitive without risking a [TypeError].
///
/// ```dart
/// final Object? raw = someExternalValue;
/// final id    = raw.asString();
/// final count = raw.asInt(fallback: -1);
/// final flag  = raw.asBool();
/// ```
extension ObjectCoercionX on Object? {
  /// Coerces to [String].
  ///
  /// Returns `toString()` for non-null values, or [fallback] when `null`.
  String asString({String fallback = ''}) => switch (this) {
        null => fallback,
        final String v => v,
        final Object v => v.toString(),
      };

  /// Coerces to `int`, parsing strings if needed.
  ///
  /// - `int` → returned directly.
  /// - `double` → truncated via `.toInt()`.
  /// - `String` → parsed via [int.tryParse].
  /// - Any other value returns [fallback].
  int asInt({int fallback = 0}) => switch (this) {
        null => fallback,
        final int v => v,
        final double v => v.toInt(),
        final String v => int.tryParse(v) ?? fallback,
        _ => fallback,
      };

  /// Coerces to `double`, parsing strings if needed.
  double asDouble({double fallback = 0.0}) => switch (this) {
        null => fallback,
        final double v => v,
        final int v => v.toDouble(),
        final String v => double.tryParse(v) ?? fallback,
        _ => fallback,
      };

  /// Coerces to `bool`.
  ///
  /// - `bool` → returned directly.
  /// - `1` / `0` integers and `'true'` / `'false'` strings (case-insensitive)
  ///   are coerced.
  /// - Any other value returns [fallback].
  bool asBool({bool fallback = false}) => switch (this) {
        null => fallback,
        final bool v => v,
        final int v => v != 0,
        final String v => switch (v.toLowerCase()) {
            'true' || '1' => true,
            'false' || '0' => false,
            _ => fallback,
          },
        _ => fallback,
      };

  /// Returns this value as [Map<String, dynamic>], or `null` if it is not a map.
  Map<String, dynamic>? asJsonMap() => switch (this) {
        final Map<String, dynamic> m => m,
        final Map<Object?, Object?> m => m.cast<String, dynamic>(),
        _ => null,
      };

  /// Returns this value as `List<T>`, filtering elements that are not [T].
  ///
  /// Returns an empty list if the value is not a [List].
  List<T> asListOf<T>() => switch (this) {
        final List<dynamic> l => l.whereType<T>().toList(),
        _ => const [],
      };
}

/// JSON-parsing helpers on [String].
///
/// ```dart
/// final body = responseString.parseJsonMap();  // throws on bad JSON
/// final safe = responseString.tryParseJsonMap(); // null on bad JSON
/// final n    = '42'.toIntOrNull();
/// ```
extension JsonStringX on String {
  /// Parses this string as a JSON object.
  ///
  /// Throws [FormatException] if the string is not valid JSON or the top-level
  /// value is not a JSON object (e.g. a JSON array or primitive).
  Map<String, dynamic> parseJsonMap() => switch (jsonDecode(this)) {
        final Map<String, dynamic> m => m,
        final Map<Object?, Object?> m => m.cast<String, dynamic>(),
        final Object other => throw FormatException(
            'Expected a JSON object, got ${other.runtimeType}',
          ),
        // ignore: dead_code
        null => throw const FormatException('Expected a JSON object, got null'),
      };

  /// Parses this string as a JSON object, returning `null` on any failure.
  Map<String, dynamic>? tryParseJsonMap() {
    try {
      return switch (jsonDecode(this)) {
        final Map<String, dynamic> m => m,
        final Map<Object?, Object?> m => m.cast<String, dynamic>(),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  /// Converts this string to an `int` via [int.tryParse], returning `null`
  /// on failure.
  int? toIntOrNull() => int.tryParse(this);

  /// Converts this string to an `int` via [int.tryParse], returning [fallback]
  /// on failure.
  int toIntOr(int fallback) => int.tryParse(this) ?? fallback;

  /// Converts this string to a `double` via [double.tryParse], returning
  /// `null` on failure.
  double? toDoubleOrNull() => double.tryParse(this);

  /// Returns `true` if this string is `'true'` (case-insensitive) or `'1'`.
  bool get isTruthy => switch (toLowerCase()) {
        'true' || '1' => true,
        _ => false,
      };
}
