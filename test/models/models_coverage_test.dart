/// Coverage top-up tests for model helpers that are not exercised by the
/// primary model tests: copyWith, equality, hashCode, toString, and the
/// lesser-used models (BroadcastSource, BroadcastOptions, SendMailOptions,
/// EmailTemplate).
library;

import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

void main() {
  // ── EmailSender ─────────────────────────────────────────────────────────────
  group('EmailSender', () {
    const base = EmailSender(address: 'a@b.com', name: 'Alice');

    test('copyWith updates address', () {
      expect(base.copyWith(address: 'x@y.com').address, 'x@y.com');
    });

    test('copyWith updates name', () {
      expect(base.copyWith(name: 'Bob').name, 'Bob');
    });

    test('copyWith keeps originals when nothing supplied', () {
      final copy = base.copyWith();
      expect(copy.address, base.address);
      expect(copy.name, base.name);
    });

    test('equality on identical values', () {
      expect(base, const EmailSender(address: 'a@b.com', name: 'Alice'));
    });

    test('not equal when name differs', () {
      expect(base, isNot(const EmailSender(address: 'a@b.com', name: 'Bob')));
    });

    test('hashCode matches for equal objects', () {
      expect(
        base.hashCode,
        const EmailSender(address: 'a@b.com', name: 'Alice').hashCode,
      );
    });

    test('toString contains address and name', () {
      expect(base.toString(), contains('a@b.com'));
      expect(base.toString(), contains('Alice'));
    });

    test('toJson omits name when null', () {
      const s = EmailSender(address: 'x@y.com');
      expect(s.toJson().containsKey('name'), isFalse);
    });
  });

  // ── EmailRecipient ───────────────────────────────────────────────────────────
  group('EmailRecipient', () {
    const base = EmailRecipient(
      address: 'r@example.com',
      name: 'Rex',
      variables: <String, dynamic>{'plan': 'pro'},
    );

    test('copyWith updates address', () {
      expect(base.copyWith(address: 'z@z.com').address, 'z@z.com');
    });

    test('copyWith keeps originals when nothing supplied', () {
      expect(base.copyWith().name, 'Rex');
    });

    test('equality on address + name', () {
      expect(
        base,
        const EmailRecipient(address: 'r@example.com', name: 'Rex'),
      );
    });

    test('not equal when address differs', () {
      expect(
        base,
        isNot(const EmailRecipient(address: 'other@example.com', name: 'Rex')),
      );
    });

    test('hashCode matches for equal objects', () {
      expect(
        base.hashCode,
        const EmailRecipient(address: 'r@example.com', name: 'Rex').hashCode,
      );
    });

    test('toString contains address', () {
      expect(base.toString(), contains('r@example.com'));
    });

    test('toJson includes variables when present', () {
      final json = base.toJson();
      expect(json['variables'], <String, dynamic>{'plan': 'pro'});
    });

    test('toJson omits variables when null', () {
      const r = EmailRecipient(address: 'x@y.com');
      expect(r.toJson().containsKey('variables'), isFalse);
    });
  });

  // ── EmailAttachment ──────────────────────────────────────────────────────────
  group('EmailAttachment', () {
    test('fromUrl creates UrlEmailAttachment', () {
      final a =
          EmailAttachment.fromUrl(name: 'file.pdf', url: 'https://x.com/f.pdf');
      expect(a, isA<UrlEmailAttachment>());
    });

    test('fromContent creates ContentEmailAttachment', () {
      final a =
          EmailAttachment.fromContent(name: 'file.txt', content: 'aGVsbG8=');
      expect(a, isA<ContentEmailAttachment>());
    });

    test('fromUrl throws on empty name', () {
      expect(
        () => EmailAttachment.fromUrl(name: '', url: 'https://x.com/f.pdf'),
        throwsA(isA<EnsendValidationException>()),
      );
    });

    test('fromUrl throws on empty url', () {
      expect(
        () => EmailAttachment.fromUrl(name: 'f.pdf', url: ''),
        throwsA(isA<EnsendValidationException>()),
      );
    });

    test('fromContent throws on empty name', () {
      expect(
        () => EmailAttachment.fromContent(name: '', content: 'abc'),
        throwsA(isA<EnsendValidationException>()),
      );
    });

    test('fromContent throws on empty content', () {
      expect(
        () => EmailAttachment.fromContent(name: 'f.txt', content: ''),
        throwsA(isA<EnsendValidationException>()),
      );
    });

    test('UrlEmailAttachment.toJson contains url', () {
      final a =
          EmailAttachment.fromUrl(name: 'r.pdf', url: 'https://x.com/r.pdf');
      expect(a.toJson(), {'name': 'r.pdf', 'url': 'https://x.com/r.pdf'});
    });

    test('ContentEmailAttachment.toJson contains content', () {
      final a = EmailAttachment.fromContent(name: 'r.txt', content: 'aGk=');
      expect(a.toJson(), {'name': 'r.txt', 'content': 'aGk='});
    });

    test('UrlEmailAttachment equality', () {
      final a =
          EmailAttachment.fromUrl(name: 'f.pdf', url: 'https://x.com/f.pdf');
      final b =
          EmailAttachment.fromUrl(name: 'f.pdf', url: 'https://x.com/f.pdf');
      expect(a, b);
    });

    test('ContentEmailAttachment equality', () {
      final a = EmailAttachment.fromContent(name: 'f.txt', content: 'aGk=');
      final b = EmailAttachment.fromContent(name: 'f.txt', content: 'aGk=');
      expect(a, b);
    });

    test('UrlEmailAttachment hashCode consistent', () {
      final a =
          EmailAttachment.fromUrl(name: 'f.pdf', url: 'https://x.com/f.pdf');
      final b =
          EmailAttachment.fromUrl(name: 'f.pdf', url: 'https://x.com/f.pdf');
      expect(a.hashCode, b.hashCode);
    });

    test('exhaustive switch on sealed subtype', () {
      final EmailAttachment a =
          EmailAttachment.fromUrl(name: 'x.pdf', url: 'https://cdn.co/x.pdf');
      final label = switch (a) {
        UrlEmailAttachment(:final url) => 'url:$url',
        ContentEmailAttachment(:final content) => 'content:$content',
      };
      expect(label, startsWith('url:'));
    });

    test('toString includes name', () {
      final a =
          EmailAttachment.fromUrl(name: 'doc.pdf', url: 'https://x.co/d.pdf');
      expect(a.toString(), contains('doc.pdf'));
    });
  });

  // ── EmailTemplate ────────────────────────────────────────────────────────────
  group('EmailTemplate', () {
    const base = EmailTemplate(
      ref: 'welcome',
      variables: <String, dynamic>{'app': 'Acme'},
    );

    test('toJson includes ref', () {
      expect(base.toJson()['ref'], 'welcome');
    });

    test('toJson includes variables when non-empty', () {
      expect(base.toJson()['variables'], <String, dynamic>{'app': 'Acme'});
    });

    test('toJson omits variables when null', () {
      const t = EmailTemplate(ref: 'plain');
      expect(t.toJson().containsKey('variables'), isFalse);
    });

    test('toJson omits variables when empty map', () {
      const t = EmailTemplate(ref: 'plain', variables: <String, dynamic>{});
      expect(t.toJson().containsKey('variables'), isFalse);
    });

    test('copyWith updates ref', () {
      expect(base.copyWith(ref: 'goodbye').ref, 'goodbye');
    });

    test('copyWith keeps variables when not supplied', () {
      expect(
        base.copyWith(ref: 'x').variables,
        <String, dynamic>{'app': 'Acme'},
      );
    });

    test('equality based on ref only', () {
      expect(
        base,
        const EmailTemplate(
          ref: 'welcome',
          variables: <String, dynamic>{'x': 1},
        ),
      );
    });

    test('hashCode matches for equal refs', () {
      expect(base.hashCode, const EmailTemplate(ref: 'welcome').hashCode);
    });

    test('toString contains ref', () {
      expect(base.toString(), contains('welcome'));
    });
  });

  // ── SendMailOptions ──────────────────────────────────────────────────────────
  group('SendMailOptions', () {
    const base = SendMailOptions(acquiringAudience: 'aud_123');

    test('toJson includes acquiringAudience when set', () {
      expect(base.toJson()['acquiringAudience'], 'aud_123');
    });

    test('toJson is empty when acquiringAudience is null', () {
      const o = SendMailOptions();
      expect(o.toJson(), isEmpty);
    });

    test('copyWith updates acquiringAudience', () {
      expect(
        base.copyWith(acquiringAudience: 'aud_456').acquiringAudience,
        'aud_456',
      );
    });

    test('equality on same acquiringAudience', () {
      expect(base, const SendMailOptions(acquiringAudience: 'aud_123'));
    });

    test('not equal when acquiringAudience differs', () {
      expect(base, isNot(const SendMailOptions(acquiringAudience: 'aud_999')));
    });

    test('hashCode consistent', () {
      expect(
        base.hashCode,
        const SendMailOptions(acquiringAudience: 'aud_123').hashCode,
      );
    });
  });

  // ── BroadcastOptions ────────────────────────────────────────────────────────
  group('BroadcastOptions', () {
    final scheduled = DateTime.utc(2026, 12, 1, 9);
    final base = BroadcastOptions(
      scheduleFor: scheduled,
      acquiringAudience: 'aud_abc',
    );

    test('toJson includes scheduleFor as ISO-8601', () {
      expect(base.toJson()['scheduleFor'], scheduled.toUtc().toIso8601String());
    });

    test('toJson includes acquiringAudience', () {
      expect(base.toJson()['acquiringAudience'], 'aud_abc');
    });

    test('toJson is empty when all fields are null', () {
      const o = BroadcastOptions();
      expect(o.toJson(), isEmpty);
    });

    test('copyWith updates scheduleFor', () {
      final later = DateTime.utc(2027);
      expect(base.copyWith(scheduleFor: later).scheduleFor, later);
    });

    test('copyWith keeps originals when nothing supplied', () {
      expect(base.copyWith().acquiringAudience, 'aud_abc');
    });

    test('equality on same fields', () {
      expect(
        base,
        BroadcastOptions(scheduleFor: scheduled, acquiringAudience: 'aud_abc'),
      );
    });

    test('not equal when acquiringAudience differs', () {
      expect(
        base,
        isNot(BroadcastOptions(scheduleFor: scheduled, acquiringAudience: 'x')),
      );
    });

    test('hashCode consistent', () {
      expect(
        base.hashCode,
        BroadcastOptions(
          scheduleFor: scheduled,
          acquiringAudience: 'aud_abc',
        ).hashCode,
      );
    });
  });

  // ── BroadcastSource ──────────────────────────────────────────────────────────
  group('BroadcastSource', () {
    test('audience source toJson contains config', () {
      final src = BroadcastSource.audience(
        const AudienceSourceConfig(ref: 'grp_1'),
      );
      final json = src.toJson();
      expect((json['config'] as Map<String, dynamic>)['ref'], 'grp_1');
    });

    test('audience source config respects actionOnExistingTrait override', () {
      final src = BroadcastSource.audience(
        const AudienceSourceConfig(
          ref: 'grp_2',
          actionOnExistingTrait: ActionOnExisting.override,
        ),
      );
      final config = (src.toJson()['config'] as Map<String, dynamic>);
      expect(config['actionOnExistingTrait'], 'override');
    });

    test('audience source config includeUnsubscribed defaults to false', () {
      final src = BroadcastSource.audience(
        const AudienceSourceConfig(
          ref: 'grp_3',
        ),
      );
      final config = (src.toJson()['config'] as Map<String, dynamic>);
      expect(config['includeUnsubscribed'], isFalse);
    });

    test('csv source toJson contains type: CSV', () {
      final src = BroadcastSource.csv(
        const CsvSourceConfig(
          label: 'users',
          url: 'https://cdn.co/users.csv',
          columnMappings: {'Email': 'address'},
        ),
      );
      final json = src.toJson();
      expect(json['type'], 'CSV');
      final config = json['config'] as Map<String, dynamic>;
      expect(config['label'], 'users');
      expect(config['url'], 'https://cdn.co/users.csv');
      expect(config['columnMappings'], {'Email': 'address'});
    });
  });

  // ── EnsendException toString ─────────────────────────────────────────────────
  group('EnsendException toString', () {
    test('EnsendNetworkException without cause', () {
      const e = EnsendNetworkException('timeout');
      expect(e.toString(), contains('EnsendNetworkException'));
      expect(e.toString(), contains('timeout'));
    });

    test('EnsendNetworkException with cause', () {
      final inner = Exception('inner');
      final e = EnsendNetworkException('net error', cause: inner);
      expect(e.toString(), contains('caused by'));
    });

    test('EnsendTimeoutException', () {
      const e = EnsendTimeoutException('timed out');
      expect(e.toString(), contains('EnsendTimeoutException'));
      expect(e.toString(), contains('timed out'));
    });

    test('EnsendSerializationException without cause', () {
      const e = EnsendSerializationException('bad JSON');
      expect(e.toString(), contains('EnsendSerializationException'));
    });

    test('EnsendSerializationException with cause', () {
      const inner = FormatException('oops');
      const e = EnsendSerializationException('parse failed', cause: inner);
      expect(e.toString(), contains('caused by'));
    });

    test('EnsendValidationException', () {
      const e = EnsendValidationException('subject required');
      expect(e.toString(), contains('EnsendValidationException'));
      expect(e.toString(), contains('subject required'));
    });

    test('EnsendException.message is accessible', () {
      const e = EnsendValidationException('msg');
      expect(e.message, 'msg');
    });
  });
}
