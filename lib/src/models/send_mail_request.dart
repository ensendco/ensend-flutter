import 'package:meta/meta.dart';

import '../exceptions.dart';
import 'email_attachment.dart';
import 'email_recipient.dart';
import 'email_sender.dart';
import 'email_template.dart';
import 'send_mail_options.dart';

/// Request payload for sending a transactional email to up to 10 recipients.
///
/// Either [message] or [template] must be supplied — both can coexist if you
/// want a fallback. Recipients are capped at 10; use
/// [BroadcastMailRequest] for larger lists (up to 250 per batch).
///
/// ```dart
/// final request = SendMailRequest(
///   subject: 'Welcome aboard!',
///   sender: EmailSender(address: 'hello@acme.com', name: 'Acme'),
///   recipients: [EmailRecipient(address: 'user@example.com', name: 'Alice')],
///   message: '<h1>Welcome, Alice!</h1>',
/// );
/// ```
@immutable
class SendMailRequest {
  static const int _maxRecipients = 10;

  /// The email subject line.
  final String subject;

  /// The verified sender identity.
  final EmailSender sender;

  /// The list of recipients. Maximum 10.
  final List<EmailRecipient> recipients;

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

  /// Optional send-level settings.
  final SendMailOptions? options;

  const SendMailRequest({
    required this.subject,
    required this.sender,
    required this.recipients,
    this.message,
    this.template,
    this.preheader,
    this.replyAddress,
    this.attachments,
    this.options,
  });

  /// Validates the request before sending and throws [EnsendValidationException]
  /// on any constraint violation.
  void validate() {
    if (subject.isEmpty) {
      throw const EnsendValidationException('subject must not be empty');
    }
    if (recipients.isEmpty) {
      throw const EnsendValidationException('At least one recipient is required');
    }
    if (recipients.length > _maxRecipients) {
      throw EnsendValidationException(
        'SendMailRequest supports at most $_maxRecipients recipients. '
        'Use BroadcastMailRequest for larger lists.',
      );
    }
    if (message == null && template == null) {
      throw EnsendValidationException(
        'Either message or template must be provided',
      );
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'subject': subject,
      'sender': sender.toJson(),
      'recipients': recipients.map((r) => r.toJson()).toList(),
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

  SendMailRequest copyWith({
    String? subject,
    EmailSender? sender,
    List<EmailRecipient>? recipients,
    String? message,
    EmailTemplate? template,
    String? preheader,
    String? replyAddress,
    List<EmailAttachment>? attachments,
    SendMailOptions? options,
  }) =>
      SendMailRequest(
        subject: subject ?? this.subject,
        sender: sender ?? this.sender,
        recipients: recipients ?? this.recipients,
        message: message ?? this.message,
        template: template ?? this.template,
        preheader: preheader ?? this.preheader,
        replyAddress: replyAddress ?? this.replyAddress,
        attachments: attachments ?? this.attachments,
        options: options ?? this.options,
      );

  @override
  String toString() =>
      'SendMailRequest(subject: $subject, recipients: ${recipients.length})';
}
