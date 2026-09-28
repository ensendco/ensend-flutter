import 'package:ensend_sdk/ensend_sdk.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // SmtpEncryption enum
  // ---------------------------------------------------------------------------
  group('SmtpEncryption', () {
    test('starttls has port 587', () {
      expect(SmtpEncryption.starttls.port, 587);
    });

    test('starttls has useSsl = false', () {
      expect(SmtpEncryption.starttls.useSsl, isFalse);
    });

    test('ssl has port 465', () {
      expect(SmtpEncryption.ssl.port, 465);
    });

    test('ssl has useSsl = true', () {
      expect(SmtpEncryption.ssl.useSsl, isTrue);
    });

    test('all values are covered', () {
      expect(SmtpEncryption.values, hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendSmtpConfig default constructor
  // ---------------------------------------------------------------------------
  group('EnsendSmtpConfig — STARTTLS (default)', () {
    const smtp =
        EnsendSmtpConfig(publicKey: 'test-public-key', secret: 'test-secret');

    test('host is smtp.ensend.co', () {
      expect(smtp.host, 'smtp.ensend.co');
    });

    test('port is 587', () {
      expect(smtp.port, 587);
    });

    test('useSsl is false', () {
      expect(smtp.useSsl, isFalse);
    });

    test('username equals publicKey', () {
      expect(smtp.username, 'test-public-key');
    });

    test('password equals secret', () {
      expect(smtp.password, 'test-secret');
    });

    test('encryption is starttls', () {
      expect(smtp.encryption, SmtpEncryption.starttls);
    });

    test('toMap returns expected shape', () {
      final map = smtp.toMap();
      expect(map['host'], 'smtp.ensend.co');
      expect(map['port'], 587);
      expect(map['secure'], isFalse);
      expect((map['auth'] as Map<String, dynamic>)['user'], 'test-public-key');
      expect((map['auth'] as Map<String, dynamic>)['pass'], 'test-secret');
    });

    test('toString includes host, port, and encryption name', () {
      expect(smtp.toString(), contains('smtp.ensend.co'));
      expect(smtp.toString(), contains('587'));
      expect(smtp.toString(), contains('starttls'));
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendSmtpConfig.ssl factory
  // ---------------------------------------------------------------------------
  group('EnsendSmtpConfig.ssl factory', () {
    final smtp = EnsendSmtpConfig.ssl(
      publicKey: 'test-public-key',
      secret: 'test-secret',
    );

    test('port is 465', () {
      expect(smtp.port, 465);
    });

    test('useSsl is true', () {
      expect(smtp.useSsl, isTrue);
    });

    test('encryption is ssl', () {
      expect(smtp.encryption, SmtpEncryption.ssl);
    });

    test('toMap reflects secure: true', () {
      expect(smtp.toMap()['secure'], isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // EnsendSmtpConfig — explicit ssl encryption
  // ---------------------------------------------------------------------------
  group('EnsendSmtpConfig — explicit SmtpEncryption.ssl', () {
    const smtp = EnsendSmtpConfig(
      publicKey: 'test-public-key',
      secret: 'test-secret',
      encryption: SmtpEncryption.ssl,
    );

    test('port is 465', () => expect(smtp.port, 465));
    test('useSsl is true', () => expect(smtp.useSsl, isTrue));
  });

  // ---------------------------------------------------------------------------
  // EnsendClient.smtpConfig convenience method
  // ---------------------------------------------------------------------------
  group('EnsendClient.smtpConfig', () {
    late EnsendClient client;

    setUp(() => client = EnsendClient(secret: 'test-secret'));
    tearDown(() => client.close());

    test('defaults to STARTTLS (port 587)', () {
      final smtp = client.smtpConfig(publicKey: 'test-public-key');
      expect(smtp.port, 587);
      expect(smtp.useSsl, isFalse);
    });

    test('ssl: true gives port 465', () {
      final smtp = client.smtpConfig(publicKey: 'test-public-key', ssl: true);
      expect(smtp.port, 465);
      expect(smtp.useSsl, isTrue);
    });

    test('propagates client secret as smtp password', () {
      final smtp = client.smtpConfig(publicKey: 'test-public-key');
      expect(smtp.password, 'test-secret');
    });
  });
}
