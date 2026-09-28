/// Safe, coercing accessors for [Map<String, dynamic>] JSON payloads.
///
/// All getters prefer a sensible default over throwing, making response
/// parsing resilient to unexpected shapes from the Ensend API or any
/// proxy that sits in front of it.
///
/// ```dart
/// result.when(
///   onSuccess: (data) {
///     final id     = data.getString('id');
///     final count  = data.getInt('count', fallback: 0);
///     final active = data.getBool('active');
///     final meta   = data.getMap('metadata');   // Map<String, dynamic>?
///   },
///   onError: (e) => print(e.message),
/// );
/// ```
extension JsonMapX on Map<String, dynamic> {
  // ── String ──────────────────────────────────────────────────────────────────

  /// Returns the string at [key].
  ///
  /// Non-null, non-`String` values are coerced via `.toString()`.
  /// Returns [fallback] when the key is absent or the value is `null`.
  String getString(String key, {String fallback = ''}) => switch (this[key]) {
        null => fallback,
        final String v => v,
        final Object v => v.toString(),
      };

  /// Returns the string at [key], or `null` if absent or `null`.
  ///
  /// Non-null, non-`String` values are coerced via `.toString()`.
  String? getStringOrNull(String key) => switch (this[key]) {
        null => null,
        final String v => v,
        final Object v => v.toString(),
      };

  // ── int ─────────────────────────────────────────────────────────────────────

  /// Returns the integer at [key].
  ///
  /// - `int` values are returned directly.
  /// - `double` values are truncated via `.toInt()`.
  /// - `String` values are parsed via [int.tryParse].
  /// - Any other value (including `null`) returns [fallback].
  int getInt(String key, {int fallback = 0}) => switch (this[key]) {
        null => fallback,
        final int v => v,
        final double v => v.toInt(),
        final String v => int.tryParse(v) ?? fallback,
        _ => fallback,
      };

  /// Returns the integer at [key], or `null` if absent, `null`, or unparseable.
  int? getIntOrNull(String key) => switch (this[key]) {
        null => null,
        final int v => v,
        final double v => v.toInt(),
        final String v => int.tryParse(v),
        _ => null,
      };

  // ── double ───────────────────────────────────────────────────────────────────

  /// Returns the double at [key].
  ///
  /// - `double` values are returned directly.
  /// - `int` values are promoted via `.toDouble()`.
  /// - `String` values are parsed via [double.tryParse].
  /// - Any other value returns [fallback].
  double getDouble(String key, {double fallback = 0.0}) => switch (this[key]) {
        null => fallback,
        final double v => v,
        final int v => v.toDouble(),
        final String v => double.tryParse(v) ?? fallback,
        _ => fallback,
      };

  /// Returns the double at [key], or `null` if absent, `null`, or unparseable.
  double? getDoubleOrNull(String key) => switch (this[key]) {
        null => null,
        final double v => v,
        final int v => v.toDouble(),
        final String v => double.tryParse(v),
        _ => null,
      };

  // ── bool ─────────────────────────────────────────────────────────────────────

  /// Returns the bool at [key].
  ///
  /// - `bool` values are returned directly.
  /// - `1` / `0` integers and `'true'` / `'false'` strings (case-insensitive)
  ///   are coerced.
  /// - Any other value returns [fallback].
  bool getBool(String key, {bool fallback = false}) => switch (this[key]) {
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

  /// Returns the bool at [key], or `null` if absent, `null`, or unrecognised.
  bool? getBoolOrNull(String key) => switch (this[key]) {
        null => null,
        final bool v => v,
        final int v => v != 0,
        final String v => switch (v.toLowerCase()) {
            'true' || '1' => true,
            'false' || '0' => false,
            _ => null,
          },
        _ => null,
      };

  // ── Nested map ────────────────────────────────────────────────────────────────

  /// Returns the nested object at [key] as [Map<String, dynamic>].
  ///
  /// Returns `null` when the key is absent, the value is `null`, or the value
  /// is not a [Map].
  Map<String, dynamic>? getMap(String key) => switch (this[key]) {
        final Map<String, dynamic> m => m,
        final Map<Object?, Object?> m => m.cast<String, dynamic>(),
        _ => null,
      };

  // ── Lists ─────────────────────────────────────────────────────────────────────

  /// Returns the list at [key] with elements that are instances of [T].
  ///
  /// Elements that cannot be cast to [T] are silently dropped. Returns an
  /// empty list when the key is absent, the value is `null`, or the value is
  /// not a [List].
  List<T> getList<T>(String key) => switch (this[key]) {
        final List<dynamic> l => l.whereType<T>().toList(),
        _ => const [],
      };

  /// Returns the list of JSON objects at [key], filtering out any elements
  /// that are not [Map]-shaped.
  List<Map<String, dynamic>> getMapList(String key) => switch (this[key]) {
        final List<dynamic> l => l
            .whereType<Map<Object?, Object?>>()
            .map((e) => e.cast<String, dynamic>())
            .toList(),
        _ => const [],
      };

  // ── Presence ──────────────────────────────────────────────────────────────────

  /// Returns `true` if [key] is present and its value is not `null`.
  bool hasValue(String key) => this[key] != null;
}
