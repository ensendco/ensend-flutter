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
    const smtp = EnsendSmtpConfig(publicKey: 'pk_123', secret: 'sk_abc');

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
      expect(smtp.username, 'pk_123');
    });

    test('password equals secret', () {
      expect(smtp.password, 'sk_abc');
    });

    test('encryption is starttls', () {
      expect(smtp.encryption, SmtpEncryption.starttls);
    });

    test('toMap returns expected shape', () {
      final map = smtp.toMap();
      expect(map['host'], 'smtp.ensend.co');
      expect(map['port'], 587);
      expect(map['secure'], isFalse);
      expect((map['auth'] as Map<String, dynamic>)['user'], 'pk_123');
      expect((map['auth'] as Map<String, dynamic>)['pass'], 'sk_abc');
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
    final smtp = EnsendSmtpConfig.ssl(publicKey: 'pk_123', secret: 'sk_abc');

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
      publicKey: 'pk_xyz',
      secret: 'sk_xyz',
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

    setUp(() => client = EnsendClient(secret: 'sk_live'));
    tearDown(() => client.close());

    test('defaults to STARTTLS (port 587)', () {
      final smtp = client.smtpConfig(publicKey: 'pk_123');
      expect(smtp.port, 587);
      expect(smtp.useSsl, isFalse);
    });

    test('ssl: true gives port 465', () {
      final smtp = client.smtpConfig(publicKey: 'pk_123', ssl: true);
      expect(smtp.port, 465);
      expect(smtp.useSsl, isTrue);
    });

    test('propagates client secret as smtp password', () {
      final smtp = client.smtpConfig(publicKey: 'pk_123');
      expect(smtp.password, 'sk_live');
    });
  });
}
