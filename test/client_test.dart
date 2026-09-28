import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

import 'helpers/mock_http_client.dart';

void main() {
  group('EnsendClient (http adapter)', () {
    test('initializes with required secret', () {
      final client = EnsendClient(secret: 'sk_test_123');
      expect(client.config.secret, 'sk_test_123');
      expect(client.config.baseUrl, 'https://api.ensend.co');
      expect(client.config.enableLogging, isFalse);
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

    test('accepts enableLogging flag', () {
      final client = EnsendClient(secret: 'sk_test', enableLogging: true);
      expect(client.config.enableLogging, isTrue);
      client.close();
    });

    test('exposes send API', () {
      final client = EnsendClient(secret: 'sk_test');
      expect(client.send, isNotNull);
      client.close();
    });

    test('accepts injected http.Client', () {
      final mockHttp = MockHttpClient();
      final client = EnsendClient(secret: 'sk_test', httpClient: mockHttp);
      expect(client, isNotNull);
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

  group('EnsendClient.withAdapter', () {
    test('uses custom adapter directly', () {
      final adapter = MockEnsendHttpAdapter();
      final client = EnsendClient.withAdapter(
        secret: 'sk_test',
        adapter: adapter,
      );
      expect(client.config.secret, 'sk_test');
      // No close() — MockEnsendHttpAdapter.close() is not stubbed but not called here
    });
  });

  group('EnsendConfig', () {
    test('authHeaders contains Bearer token and JSON content type', () {
      const config = EnsendConfig(secret: 'sk_abc');
      final headers = config.authHeaders;
      expect(headers['Authorization'], 'Bearer sk_abc');
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
    });

    test('enableLogging defaults to false', () {
      const config = EnsendConfig(secret: 'sk_abc');
      expect(config.enableLogging, isFalse);
    });

    test('enableLogging can be set to true', () {
      const config = EnsendConfig(secret: 'sk_abc', enableLogging: true);
      expect(config.enableLogging, isTrue);
    });
  });

  group('EnsendLogger', () {
    test('is no-op when disabled', () {
      const logger = EnsendLogger();
      expect(logger.enabled, isFalse);
      // These should not throw
      logger.request('POST', 'https://api.ensend.co/send/mail', {});
      logger.response(200, {});
      logger.error('test error');
      logger.info('test info');
    });

    test('enabled flag is set correctly', () {
      const logger = EnsendLogger(enabled: true);
      expect(logger.enabled, isTrue);
    });
  });
}
