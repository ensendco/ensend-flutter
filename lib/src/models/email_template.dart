import 'package:meta/meta.dart';

/// References a saved Ensend template and optionally provides global
/// personalization variables.
///
/// Per-recipient overrides are set on [EmailRecipient.variables] and take
/// precedence over these global [variables].
///
/// ```dart
/// EmailTemplate(
///   ref: 'welcome-email',
///   variables: {'appName': 'Acme', 'supportEmail': 'help@acme.com'},
/// )
/// ```
@immutable
class EmailTemplate {
  /// The reference identifier of the saved template in your Ensend project.
  final String ref;

  /// Global key-value pairs for template personalization.
  /// Use `{{variable_name}}` syntax in your template body.
  final Map<String, dynamic>? variables;

  const EmailTemplate({
    required this.ref,
    this.variables,
  }) : assert(ref != '', 'ref must not be empty');

  Map<String, dynamic> toJson() => {
        'ref': ref,
        if (variables != null && variables!.isNotEmpty) 'variables': variables,
      };

  EmailTemplate copyWith({String? ref, Map<String, dynamic>? variables}) =>
      EmailTemplate(
        ref: ref ?? this.ref,
        variables: variables ?? this.variables,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmailTemplate && ref == other.ref;

  @override
  int get hashCode => ref.hashCode;

  @override
  String toString() => 'EmailTemplate(ref: $ref)';
}
