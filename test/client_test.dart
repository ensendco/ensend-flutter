import 'package:ensend_flutter/ensend_flutter.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

import 'helpers/mock_http_client.dart';

void main() {
  group('EnsendClient (http adapter)', () {
    test('initializes with required secret', () {
      final client = EnsendClient(secret: 'test-secret-123');
      expect(client.config.secret, 'test-secret-123');
      expect(client.config.baseUrl, 'https://api.ensend.co');
      expect(client.config.enableLogging, isFalse);
      client.close();
    });

    test('accepts custom baseUrl for testing', () {
      final client = EnsendClient(
        secret: 'test-secret',
        baseUrl: 'http://localhost:8080',
      );
      expect(client.config.baseUrl, 'http://localhost:8080');
      client.close();
    });

    test('accepts enableLogging flag', () {
      final client = EnsendClient(secret: 'test-secret', enableLogging: true);
      expect(client.config.enableLogging, isTrue);
      client.close();
    });

    test('exposes send API', () {
      final client = EnsendClient(secret: 'test-secret');
      expect(client.send, isNotNull);
      client.close();
    });

    test('accepts injected http.Client', () {
      final mockHttp = MockHttpClient();
      final client = EnsendClient(secret: 'test-secret', httpClient: mockHttp);
      expect(client, isNotNull);
      client.close();
    });

    group('smtpConfig', () {
      test('returns STARTTLS config on port 587 by default', () {
        final client = EnsendClient(secret: 'test-secret');
        final smtp = client.smtpConfig(publicKey: 'test-public-key');
        expect(smtp.host, 'smtp.ensend.co');
        expect(smtp.port, 587);
        expect(smtp.useSsl, isFalse);
        expect(smtp.username, 'test-public-key');
        expect(smtp.password, 'test-secret');
        client.close();
      });

      test('returns SSL config on port 465 when ssl=true', () {
        final client = EnsendClient(secret: 'test-secret');
        final smtp = client.smtpConfig(publicKey: 'test-public-key', ssl: true);
        expect(smtp.port, 465);
        expect(smtp.useSsl, isTrue);
        client.close();
      });

      test('toMap returns expected keys', () {
        final client = EnsendClient(secret: 'test-secret');
        final smtp = client.smtpConfig(publicKey: 'test-public-key');
        final map = smtp.toMap();
        expect(map['host'], 'smtp.ensend.co');
        expect(map['port'], 587);
        expect(map['auth']['user'], 'test-public-key');
        expect(map['auth']['pass'], 'test-secret');
        client.close();
      });
    });
  });

  group('EnsendClient.withAdapter', () {
    test('uses custom adapter directly', () {
      final adapter = MockEnsendHttpAdapter();
      final client = EnsendClient.withAdapter(
        secret: 'test-secret',
        adapter: adapter,
      );
      expect(client.config.secret, 'test-secret');
      // No close() — MockEnsendHttpAdapter.close() is not stubbed but not called here
    });
  });

  group('EnsendConfig', () {
    test('authHeaders contains Bearer token and JSON content type', () {
      const config = EnsendConfig(secret: 'test-secret');
      final headers = config.authHeaders;
      expect(headers['Authorization'], 'Bearer test-secret');
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
    });

    test('enableLogging defaults to false', () {
      const config = EnsendConfig(secret: 'test-secret');
      expect(config.enableLogging, isFalse);
    });

    test('enableLogging can be set to true', () {
      const config = EnsendConfig(secret: 'test-secret', enableLogging: true);
      expect(config.enableLogging, isTrue);
    });
  });

  group('EnsendLogger', () {
    test('is no-op when disabled', () {
      final logger = EnsendLogger();
      expect(logger.enabled, isFalse);
      // None of these should throw
      logger.request('POST', 'https://api.ensend.co/send/mail', {});
      logger.response(200, {});
      logger.error('test error');
      logger.info('test info');
      logger.warning('test warning');
    });

    test('enabled flag is set correctly', () {
      final logger = EnsendLogger(enabled: true);
      expect(logger.enabled, isTrue);
    });

    test('accepts custom Logger instance', () {
      final customLogger = Logger(printer: SimplePrinter(printTime: true));
      final ensendLogger = EnsendLogger(logger: customLogger);
      expect(ensendLogger.enabled, isFalse);
    });
  });
}
