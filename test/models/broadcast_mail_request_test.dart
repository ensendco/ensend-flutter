import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

const _sender = EmailSender(address: 'news@acme.com');
const _recipient = EmailRecipient(address: 'user@example.com');

void main() {
  group('BroadcastMailRequest', () {
    group('validate', () {
      test('throws when neither recipients nor sources are provided', () {
        const req = BroadcastMailRequest(
          subject: 'Newsletter',
          sender: _sender,
          message: 'Hello',
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('throws when more than 250 recipients', () {
        final req = BroadcastMailRequest(
          subject: 'Newsletter',
          sender: _sender,
          recipients: List.generate(
            251,
            (i) => EmailRecipient(address: 'u$i@example.com'),
          ),
          message: 'Hello',
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('throws when neither message nor template is provided', () {
        const req = BroadcastMailRequest(
          subject: 'Newsletter',
          sender: _sender,
          recipients: [_recipient],
        );
        expect(req.validate, throwsA(isA<EnsendValidationException>()));
      });

      test('passes with 250 recipients exactly', () {
        final req = BroadcastMailRequest(
          subject: 'Newsletter',
          sender: _sender,
          recipients: List.generate(
            250,
            (i) => EmailRecipient(address: 'u$i@example.com'),
          ),
          message: 'Hello',
        );
        expect(req.validate, returnsNormally);
      });
    });

    group('toJson', () {
      test('serializes with inline recipients', () {
        const req = BroadcastMailRequest(
          subject: 'Newsletter',
          sender: _sender,
          recipients: [_recipient],
          message: '<p>Hello!</p>',
        );
        final json = req.toJson();
        expect(json['subject'], 'Newsletter');
        expect(json['recipients'], hasLength(1));
        expect(json['message'], '<p>Hello!</p>');
        expect(json.containsKey('sources'), isFalse);
      });

      test('includes scheduleFor in ISO 8601 UTC format', () {
        final scheduleTime = DateTime.utc(2025, 12, 25, 10);
        final req = BroadcastMailRequest(
          subject: 'Holiday',
          sender: _sender,
          recipients: [_recipient],
          message: 'Happy holidays!',
          options: BroadcastOptions(scheduleFor: scheduleTime),
        );
        final json = req.toJson();
        expect(json['options']['scheduleFor'], contains('2025-12-25'));
      });

      test('serializes CSV source', () {
        final req = BroadcastMailRequest(
          subject: 'Promo',
          sender: _sender,
          sources: [
            BroadcastSource.csv(
              const CsvSourceConfig(
                label: 'promo-list',
                url: 'https://s3.example.com/list.csv',
                columnMappings: {'Email': 'address', 'Name': 'firstName'},
              ),
            ),
          ],
          message: 'Hello!',
        );
        final json = req.toJson();
        final source = (json['sources'] as List).first as Map;
        expect(source['type'], 'CSV');
        expect(source['config']['label'], 'promo-list');
      });
    });
  });

  group('BroadcastBatchRequest', () {
    test('throws on empty broadcastRef', () {
      const req = BroadcastBatchRequest(
        broadcastRef: '',
        recipients: [_recipient],
      );
      expect(req.validate, throwsA(isA<EnsendValidationException>()));
    });

    test('throws when no recipients or sources', () {
      const req = BroadcastBatchRequest(broadcastRef: 'bcast_123');
      expect(req.validate, throwsA(isA<EnsendValidationException>()));
    });

    test('toJson serializes correctly', () {
      const req = BroadcastBatchRequest(
        broadcastRef: 'bcast_abc',
        recipients: [_recipient],
      );
      final json = req.toJson();
      expect(json['broadcastRef'], 'bcast_abc');
      expect(json['recipients'], hasLength(1));
    });
  });
}
