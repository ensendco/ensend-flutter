import 'package:meta/meta.dart';

/// A single email recipient.
///
/// [variables] are per-recipient template variable overrides. They take
/// precedence over the global [EmailTemplate.variables] for this recipient.
///
/// ```dart
/// EmailRecipient(
///   address: 'user@example.com',
///   name: 'Jane Doe',
///   variables: {'firstName': 'Jane', 'plan': 'Pro'},
/// )
/// ```
@immutable
class EmailRecipient {
  /// The recipient's email address.
  final String address;

  /// Optional display name, used in template traits like `{{recipient.firstName}}`.
  final String? name;

  /// Per-recipient template variable overrides.
  final Map<String, dynamic>? variables;

  const EmailRecipient({
    required this.address,
    this.name,
    this.variables,
  }) : assert(address != '', 'address must not be empty');

  Map<String, dynamic> toJson() => {
        'address': address,
        if (name != null) 'name': name,
        if (variables != null && variables!.isNotEmpty) 'variables': variables,
      };

  EmailRecipient copyWith({
    String? address,
    String? name,
    Map<String, dynamic>? variables,
  }) =>
      EmailRecipient(
        address: address ?? this.address,
        name: name ?? this.name,
        variables: variables ?? this.variables,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailRecipient && address == other.address && name == other.name;

  @override
  int get hashCode => Object.hash(address, name);

  @override
  String toString() => 'EmailRecipient(address: $address, name: $name)';
}
