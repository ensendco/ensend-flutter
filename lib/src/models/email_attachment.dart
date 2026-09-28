import 'package:meta/meta.dart';

import '../exceptions.dart';

/// A file attachment for an outgoing email.
///
/// Two variants exist — use the named factories to construct them:
/// - [EmailAttachment.fromUrl] — attach a file via a publicly accessible URL.
/// - [EmailAttachment.fromContent] — attach a file via base64-encoded content.
///
/// Because [EmailAttachment] is sealed you can exhaustively switch on it:
/// ```dart
/// switch (attachment) {
///   case UrlEmailAttachment(:final url):
///     print('linked from $url');
///   case ContentEmailAttachment():
///     print('inline content, ${attachment.name}');
/// }
/// ```
@immutable
sealed class EmailAttachment {
  /// The filename as it appears to the recipient. Must include the extension,
  /// e.g. `Resume.pdf`.
  final String name;

  const EmailAttachment._(this.name);

  /// Creates an attachment from a publicly accessible file URL.
  factory EmailAttachment.fromUrl({
    required String name,
    required String url,
  }) {
    if (name.isEmpty) {
      throw const EnsendValidationException(
        'Attachment name must not be empty',
      );
    }
    if (url.isEmpty) {
      throw const EnsendValidationException('Attachment url must not be empty');
    }
    return UrlEmailAttachment._(name: name, url: url);
  }

  /// Creates an attachment from a base64-encoded string.
  factory EmailAttachment.fromContent({
    required String name,
    required String content,
  }) {
    if (name.isEmpty) {
      throw const EnsendValidationException(
        'Attachment name must not be empty',
      );
    }
    if (content.isEmpty) {
      throw const EnsendValidationException(
        'Attachment content must not be empty',
      );
    }
    return ContentEmailAttachment._(name: name, content: content);
  }

  Map<String, dynamic> toJson();

  @override
  String toString() => 'EmailAttachment(name: $name)';
}

/// An [EmailAttachment] whose content is fetched from a public URL at send time.
@immutable
final class UrlEmailAttachment extends EmailAttachment {
  /// The publicly accessible URL of the file to attach.
  final String url;

  const UrlEmailAttachment._({required String name, required this.url})
      : super._(name);

  @override
  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UrlEmailAttachment && name == other.name && url == other.url;

  @override
  int get hashCode => Object.hash(name, url);
}

/// An [EmailAttachment] whose content is provided as a base64-encoded string.
@immutable
final class ContentEmailAttachment extends EmailAttachment {
  /// Base64-encoded file content.
  final String content;

  const ContentEmailAttachment._({required String name, required this.content})
      : super._(name);

  @override
  Map<String, dynamic> toJson() => {'name': name, 'content': content};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentEmailAttachment &&
          name == other.name &&
          content == other.content;

  @override
  int get hashCode => Object.hash(name, content);
}
