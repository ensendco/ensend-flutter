import 'package:meta/meta.dart';

import '../exceptions.dart';

/// A file attachment for an outgoing email.
///
/// Provide either a public [url] or a base64-encoded [content] string —
/// exactly one must be supplied.
///
/// ```dart
/// // From a public URL:
/// EmailAttachment.fromUrl(name: 'report.pdf', url: 'https://cdn.example.com/report.pdf')
///
/// // From base64 content:
/// EmailAttachment.fromContent(name: 'invoice.pdf', content: base64Encoded)
/// ```
@immutable
class EmailAttachment {
  /// The filename as it appears to the recipient. Must include the extension,
  /// e.g. `Resume.pdf`.
  final String name;

  /// A publicly accessible URL to the file. Mutually exclusive with [content].
  final String? url;

  /// Base64-encoded file content. Mutually exclusive with [url].
  final String? content;

  const EmailAttachment._({
    required this.name,
    this.url,
    this.content,
  });

  /// Creates an attachment from a publicly accessible file URL.
  factory EmailAttachment.fromUrl({
    required String name,
    required String url,
  }) {
    if (name.isEmpty) {
      throw const EnsendValidationException('Attachment name must not be empty');
    }
    if (url.isEmpty) {
      throw const EnsendValidationException('Attachment url must not be empty');
    }
    return EmailAttachment._(name: name, url: url);
  }

  /// Creates an attachment from a base64-encoded string.
  factory EmailAttachment.fromContent({
    required String name,
    required String content,
  }) {
    if (name.isEmpty) {
      throw const EnsendValidationException('Attachment name must not be empty');
    }
    if (content.isEmpty) {
      throw const EnsendValidationException(
        'Attachment content must not be empty',
      );
    }
    return EmailAttachment._(name: name, content: content);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (url != null) 'url': url,
        if (content != null) 'content': content,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailAttachment &&
          name == other.name &&
          url == other.url &&
          content == other.content;

  @override
  int get hashCode => Object.hash(name, url, content);

  @override
  String toString() => 'EmailAttachment(name: $name)';
}
