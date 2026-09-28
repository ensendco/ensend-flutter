import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('EnsendClient', () {
    test('initializes with required secret', () {
      final client = EnsendClient(secret: 'sk_test_123');
      expect(client.config.secret, 'sk_test_123');
      expect(client.config.baseUrl, 'https://api.ensend.co');
      client.close();
    });

    test('accepts custom baseUrl for testing', () {
      final client = EnsendClient(
        secret: 'sk_test',
        baseUrl: 'http://localhost:8080',
      );
      expect(client.config.baseUrl, 'http://localhost:8080');
      client.close();
    });

    test('exposes send API', () {
      final client = EnsendClient(secret: 'sk_test');
      expect(client.send, isNotNull);
      client.close();
    });

    group('smtpConfig', () {
      test('returns STARTTLS config on port 587 by default', () {
        final client = EnsendClient(secret: 'sk_live');
        final smtp = client.smtpConfig(publicKey: 'pk_123');
        expect(smtp.host, 'smtp.ensend.co');
        expect(smtp.port, 587);
        expect(smtp.useSsl, isFalse);
        expect(smtp.username, 'pk_123');
        expect(smtp.password, 'sk_live');
        client.close();
      });

      test('returns SSL config on port 465 when ssl=true', () {
        final client = EnsendClient(secret: 'sk_live');
        final smtp = client.smtpConfig(publicKey: 'pk_123', ssl: true);
        expect(smtp.port, 465);
        expect(smtp.useSsl, isTrue);
        client.close();
      });

      test('toMap returns expected keys', () {
        final client = EnsendClient(secret: 'sk_live');
        final smtp = client.smtpConfig(publicKey: 'pk_123');
        final map = smtp.toMap();
        expect(map['host'], 'smtp.ensend.co');
        expect(map['port'], 587);
        expect(map['auth']['user'], 'pk_123');
        expect(map['auth']['pass'], 'sk_live');
        client.close();
      });
    });
  });

  group('EnsendConfig', () {
    test('authHeaders contains Bearer token and JSON content type', () {
      final config = EnsendConfig(secret: 'sk_abc');
      final headers = config.authHeaders;
      expect(headers['Authorization'], 'Bearer sk_abc');
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
    });
  });
}
