import 'dart:convert';

/// Safe type-coercion helpers for any [Object?] value.
///
/// Useful when the source is typed as `dynamic` and you need a specific
/// primitive without risking a [TypeError].
///
/// ```dart
/// final dynamic raw = someExternalValue;
/// final id    = raw.asString();
/// final count = raw.asInt(fallback: -1);
/// final flag  = raw.asBool();
/// ```
extension ObjectCoercionX on Object? {
  /// Coerces to [String].
  ///
  /// Returns `toString()` for non-null values, or [fallback] when `null`.
  String asString({String fallback = ''}) {
    final self = this;
    if (self == null) return fallback;
    return self is String ? self : self.toString();
  }

  /// Coerces to `int`, parsing strings if needed.
  ///
  /// - `int` → returned directly.
  /// - `double` → truncated via `.toInt()`.
  /// - `String` → parsed via [int.tryParse].
  /// - Any other value returns [fallback].
  int asInt({int fallback = 0}) {
    final self = this;
    if (self == null) return fallback;
    if (self is int) return self;
    if (self is double) return self.toInt();
    if (self is String) return int.tryParse(self) ?? fallback;
    return fallback;
  }

  /// Coerces to `double`, parsing strings if needed.
  double asDouble({double fallback = 0.0}) {
    final self = this;
    if (self == null) return fallback;
    if (self is double) return self;
    if (self is int) return self.toDouble();
    if (self is String) return double.tryParse(self) ?? fallback;
    return fallback;
  }

  /// Coerces to `bool`.
  ///
  /// - `bool` → returned directly.
  /// - `1` / `0` integers and `'true'` / `'false'` strings (case-insensitive)
  ///   are coerced.
  /// - Any other value returns [fallback].
  bool asBool({bool fallback = false}) {
    final self = this;
    if (self == null) return fallback;
    if (self is bool) return self;
    if (self is int) return self != 0;
    if (self is String) {
      final lower = self.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }

  /// Returns this value as [Map<String, dynamic>], or `null` if it is not a map.
  Map<String, dynamic>? asJsonMap() {
    final self = this;
    if (self is Map<String, dynamic>) return self;
    if (self is Map<Object?, Object?>) return self.cast<String, dynamic>();
    return null;
  }

  /// Returns this value as `List<T>`, filtering elements that are not [T].
  ///
  /// Returns an empty list if the value is not a [List].
  List<T> asListOf<T>() {
    final self = this;
    if (self is! List) return const [];
    return self.whereType<T>().toList();
  }
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
  Map<String, dynamic> parseJsonMap() {
    final result = jsonDecode(this);
    if (result is Map<String, dynamic>) return result;
    if (result is Map<Object?, Object?>) return result.cast<String, dynamic>();
    throw FormatException(
      'Expected a JSON object, got ${result.runtimeType}',
    );
  }

  /// Parses this string as a JSON object, returning `null` on any failure.
  Map<String, dynamic>? tryParseJsonMap() {
    try {
      final result = jsonDecode(this);
      if (result is Map<String, dynamic>) return result;
      if (result is Map<Object?, Object?>) {
        return result.cast<String, dynamic>();
      }
      return null;
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

  /// Returns `true` if this string is `'true'` (case-insensitive).
  bool get isTruthy => toLowerCase() == 'true' || this == '1';
}
