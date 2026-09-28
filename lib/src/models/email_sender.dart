import 'package:meta/meta.dart';

/// The sender identity for an outgoing email.
///
/// The [address] must be a configured sender identity in your Ensend project.
/// Your workspace includes a default `@ensend.me` address; connect a custom
/// domain for branded sending.
@immutable
class EmailSender {
  /// The sender's email address. Must match a verified sender identity.
  final String address;

  /// Optional display name. Defaults to the username part of [address].
  final String? name;

  const EmailSender({
    required this.address,
    this.name,
  }) : assert(address != '', 'address must not be empty');

  Map<String, dynamic> toJson() => {
        'address': address,
        if (name != null) 'name': name,
      };

  EmailSender copyWith({String? address, String? name}) => EmailSender(
        address: address ?? this.address,
        name: name ?? this.name,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailSender && address == other.address && name == other.name;

  @override
  int get hashCode => Object.hash(address, name);

  @override
  String toString() => 'EmailSender(address: $address, name: $name)';
}
