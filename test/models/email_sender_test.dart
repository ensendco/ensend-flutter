import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('EmailSender', () {
    test('toJson includes address and name', () {
      final sender = EmailSender(address: 'hello@acme.com', name: 'Acme');
      expect(sender.toJson(), {
        'address': 'hello@acme.com',
        'name': 'Acme',
      });
    });

    test('toJson omits name when null', () {
      final sender = EmailSender(address: 'hello@acme.com');
      expect(sender.toJson(), {'address': 'hello@acme.com'});
      expect(sender.toJson().containsKey('name'), isFalse);
    });

    test('copyWith replaces specified fields', () {
      final original = EmailSender(address: 'a@a.com', name: 'A');
      final copy = original.copyWith(name: 'B');
      expect(copy.address, 'a@a.com');
      expect(copy.name, 'B');
    });

    test('equality is based on address and name', () {
      final a = EmailSender(address: 'x@x.com', name: 'X');
      final b = EmailSender(address: 'x@x.com', name: 'X');
      expect(a, equals(b));
    });
  });
}
