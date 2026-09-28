import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('EmailSender', () {
    test('toJson includes address and name', () {
      const sender = EmailSender(address: 'hello@acme.com', name: 'Acme');
      expect(sender.toJson(), {
        'address': 'hello@acme.com',
        'name': 'Acme',
      });
    });

    test('toJson omits name when null', () {
      const sender = EmailSender(address: 'hello@acme.com');
      expect(sender.toJson(), {'address': 'hello@acme.com'});
      expect(sender.toJson().containsKey('name'), isFalse);
    });

    test('copyWith replaces specified fields', () {
      const original = EmailSender(address: 'a@a.com', name: 'A');
      final copy = original.copyWith(name: 'B');
      expect(copy.address, 'a@a.com');
      expect(copy.name, 'B');
    });

    test('equality is based on address and name', () {
      const a = EmailSender(address: 'x@x.com', name: 'X');
      const b = EmailSender(address: 'x@x.com', name: 'X');
      expect(a, equals(b));
    });
  });
}
