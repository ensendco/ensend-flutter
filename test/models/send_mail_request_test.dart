import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

const _sender = EmailSender(address: 'hello@acme.com', name: 'Acme');
const _recipient = EmailRecipient(address: 'user@example.com', name: 'Alice');

void main() {
  group('SendMailRequest', () {
    group('validate', () {
      test('throws when subject is empty', () {
        const req = SendMailRequest(
          subject: '',
          sender: _sender,
          recipients: [_recipient],
          message: 'Hello',
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('throws when recipients list is empty', () {
        const req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [],
          message: 'Hello',
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('throws when more than 10 recipients', () {
        final req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: List.generate(
            11,
            (i) => EmailRecipient(address: 'u$i@example.com'),
          ),
          message: 'Hello',
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('throws when neither message nor template is provided', () {
        const req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [_recipient],
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('passes with message only', () {
        const req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [_recipient],
          message: '<p>Hello</p>',
        );
        expect(req.validate, returnsNormally);
      });

      test('passes with template only', () {
        const req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [_recipient],
          template: EmailTemplate(ref: 'welcome'),
        );
        expect(req.validate, returnsNormally);
      });

      test('passes with exactly 10 recipients', () {
        final req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: List.generate(
            10,
            (i) => EmailRecipient(address: 'u$i@example.com'),
          ),
          message: 'Hello',
        );
        expect(req.validate, returnsNormally);
      });
    });

    group('toJson', () {
      test('serializes required fields correctly', () {
        const req = SendMailRequest(
          subject: 'Welcome!',
          sender: _sender,
          recipients: [_recipient],
          message: '<b>Hello</b>',
        );
        final json = req.toJson();
        expect(json['subject'], 'Welcome!');
        expect(json['sender'], {'address': 'hello@acme.com', 'name': 'Acme'});
        expect(json['recipients'], hasLength(1));
        expect(json['message'], '<b>Hello</b>');
      });

      test('omits null optional fields', () {
        const req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [_recipient],
          message: 'Hello',
        );
        final json = req.toJson();
        expect(json.containsKey('preheader'), isFalse);
        expect(json.containsKey('replyAddress'), isFalse);
        expect(json.containsKey('attachments'), isFalse);
        expect(json.containsKey('options'), isFalse);
      });

      test('includes optional fields when set', () {
        final req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [_recipient],
          message: 'Hello',
          preheader: 'Check this out',
          replyAddress: 'support@acme.com',
          attachments: [
            EmailAttachment.fromUrl(
              name: 'f.pdf',
              url: 'https://cdn.com/f.pdf',
            ),
          ],
          options: const SendMailOptions(acquiringAudience: 'newsletter'),
        );
        final json = req.toJson();
        expect(json['preheader'], 'Check this out');
        expect(json['replyAddress'], 'support@acme.com');
        expect(json['attachments'], hasLength(1));
        expect(json['options']['acquiringAudience'], 'newsletter');
      });

      test('serializes template variables', () {
        const req = SendMailRequest(
          subject: 'Hi',
          sender: _sender,
          recipients: [_recipient],
          template: EmailTemplate(
            ref: 'welcome',
            variables: {'app': 'Acme'},
          ),
        );
        final json = req.toJson();
        expect(json['template']['ref'], 'welcome');
        expect(json['template']['variables'], {'app': 'Acme'});
      });
    });

    test('copyWith preserves unchanged fields', () {
      const req = SendMailRequest(
        subject: 'Original',
        sender: _sender,
        recipients: [_recipient],
        message: 'Hello',
      );
      final copy = req.copyWith(subject: 'Updated');
      expect(copy.subject, 'Updated');
      expect(copy.sender, _sender);
      expect(copy.message, 'Hello');
    });
  });
}
