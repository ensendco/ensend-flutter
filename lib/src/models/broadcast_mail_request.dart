import 'package:meta/meta.dart';

import '../exceptions.dart';
import 'broadcast_options.dart';
import 'broadcast_source.dart';
import 'email_attachment.dart';
import 'email_recipient.dart';
import 'email_sender.dart';
import 'email_template.dart';

/// Request payload for initiating a new email broadcast to up to 250 recipients
/// per batch.
///
/// Either [recipients] or [sources] must be supplied (both can coexist).
/// Either [message] or [template] must be provided.
///
/// For subsequent batches on the same broadcast use [BroadcastBatchRequest].
///
/// ```dart
/// final request = BroadcastMailRequest(
///   subject: 'Our monthly newsletter',
///   sender: EmailSender(address: 'news@acme.com', name: 'Acme Newsletter'),
///   recipients: [
///     EmailRecipient(address: 'alice@example.com'),
///     EmailRecipient(address: 'bob@example.com'),
///   ],
///   message: '<h1>Hello!</h1><p>This month we launched...</p>',
/// );
/// ```
@immutable
class BroadcastMailRequest {
  static const int _maxRecipients = 250;

  /// The email subject line.
  final String subject;

  /// The verified sender identity.
  final EmailSender sender;

  /// Inline recipient list. Maximum 250 per request.
  /// Required when [sources] is not provided.
  final List<EmailRecipient>? recipients;

  /// External recipient sources (audience groups or CSV files).
  /// Required when [recipients] is not provided.
  final List<BroadcastSource>? sources;

  /// Raw HTML or plain-text message body.
  /// Required when [template] is not provided.
  final String? message;

  /// A saved template reference. Required when [message] is not provided.
  final EmailTemplate? template;

  /// Short preview text shown below the subject in supported email clients.
  final String? preheader;

  /// Email address where replies are directed.
  final String? replyAddress;

  /// Files to attach to the email.
  final List<EmailAttachment>? attachments;

  /// Optional broadcast-level settings (scheduling, audience acquisition).
  final BroadcastOptions? options;

  const BroadcastMailRequest({
    required this.subject,
    required this.sender,
    this.recipients,
    this.sources,
    this.message,
    this.template,
    this.preheader,
    this.replyAddress,
    this.attachments,
    this.options,
  });

  /// Validates the request before sending.
  void validate() {
    if (subject.isEmpty) {
      throw const EnsendValidationException('subject must not be empty');
    }
    if ((recipients == null || recipients!.isEmpty) &&
        (sources == null || sources!.isEmpty)) {
      throw const EnsendValidationException(
        'Either recipients or sources must be provided',
      );
    }
    if (recipients != null && recipients!.length > _maxRecipients) {
      throw const EnsendValidationException(
        'BroadcastMailRequest supports at most $_maxRecipients recipients per batch.',
      );
    }
    if (message == null && template == null) {
      throw const EnsendValidationException(
        'Either message or template must be provided',
      );
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'subject': subject,
      'sender': sender.toJson(),
      if (recipients != null && recipients!.isNotEmpty)
        'recipients': recipients!.map((r) => r.toJson()).toList(),
      if (sources != null && sources!.isNotEmpty)
        'sources': sources!.map((s) => s.toJson()).toList(),
      if (message != null) 'message': message,
      if (template != null) 'template': template!.toJson(),
      if (preheader != null) 'preheader': preheader,
      if (replyAddress != null) 'replyAddress': replyAddress,
      if (attachments != null && attachments!.isNotEmpty)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
      if (options != null && options!.toJson().isNotEmpty)
        'options': options!.toJson(),
    };
  }

  @override
  String toString() =>
      'BroadcastMailRequest(subject: $subject, recipients: ${recipients?.length ?? 0})';
}
