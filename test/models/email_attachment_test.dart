import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('EmailAttachment', () {
    group('fromUrl', () {
      test('toJson includes name and url', () {
        final att = EmailAttachment.fromUrl(
          name: 'report.pdf',
          url: 'https://cdn.acme.com/report.pdf',
        );
        expect(att.toJson(), {
          'name': 'report.pdf',
          'url': 'https://cdn.acme.com/report.pdf',
        });
        expect(att.toJson().containsKey('content'), isFalse);
      });

      test('throws on empty name', () {
        expect(
          () => EmailAttachment.fromUrl(name: '', url: 'https://example.com/f.pdf'),
          throwsA(isA<EnsendValidationException>()),
        );
      });

      test('throws on empty url', () {
        expect(
          () => EmailAttachment.fromUrl(name: 'file.pdf', url: ''),
          throwsA(isA<EnsendValidationException>()),
        );
      });
    });

    group('fromContent', () {
      test('toJson includes name and content', () {
        final att = EmailAttachment.fromContent(
          name: 'invoice.pdf',
          content: 'base64data==',
        );
        expect(att.toJson(), {
          'name': 'invoice.pdf',
          'content': 'base64data==',
        });
        expect(att.toJson().containsKey('url'), isFalse);
      });

      test('throws on empty content', () {
        expect(
          () => EmailAttachment.fromContent(name: 'file.pdf', content: ''),
          throwsA(isA<EnsendValidationException>()),
        );
      });
    });
  });
}
