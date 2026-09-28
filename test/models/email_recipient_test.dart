import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('EmailRecipient', () {
    test('toJson includes all non-null fields', () {
      const recipient = EmailRecipient(
        address: 'user@example.com',
        name: 'Alice',
        variables: {'plan': 'Pro'},
      );
      expect(recipient.toJson(), {
        'address': 'user@example.com',
        'name': 'Alice',
        'variables': {'plan': 'Pro'},
      });
    });

    test('toJson omits optional fields when null', () {
      const recipient = EmailRecipient(address: 'user@example.com');
      final json = recipient.toJson();
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('variables'), isFalse);
    });

    test('toJson omits variables when empty map', () {
      const recipient = EmailRecipient(
        address: 'user@example.com',
        variables: {},
      );
      expect(recipient.toJson().containsKey('variables'), isFalse);
    });

    test('copyWith replaces specified fields', () {
      const original = EmailRecipient(address: 'a@a.com', name: 'A');
      final copy = original.copyWith(name: 'B', variables: {'x': 1});
      expect(copy.address, 'a@a.com');
      expect(copy.name, 'B');
      expect(copy.variables, {'x': 1});
    });

    test('equality based on address and name', () {
      expect(
        const EmailRecipient(address: 'a@a.com', name: 'A'),
        equals(const EmailRecipient(address: 'a@a.com', name: 'A')),
      );
    });
  });
}
