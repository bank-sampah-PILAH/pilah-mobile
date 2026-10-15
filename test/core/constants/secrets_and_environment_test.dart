import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/constants/secrets.dart';

void main() {
  tearDown(() => dotenv.loadFromString(envString: '', isOptional: true));

  group('with a configured .env', () {
    setUp(() => dotenv.loadFromString(envString: '''
BASE_URL_DEV=http://dev.test
BASE_URL_PROD=https://prod.test
ENABLE_DEMO_LOGIN=TRUE
DEMO_PENGURUS_EMAIL=pengurus@x.test
DEMO_PENGELOLA_INDUK_EMAIL=induk@x.test
DEMO_CUSTOMER_EMAIL=nasabah@x.test
DEMO_NEW_NASABAH_EMAIL=baru@x.test
DEMO_SUPERADMIN_EMAIL=super@x.test
'''));

    test('Secret reads every value from the environment file', () {
      expect(Secret.baseUrlDev, 'http://dev.test');
      expect(Secret.baseUrlProd, 'https://prod.test');
      expect(Secret.demoLoginEnabled, isTrue);
      expect(Secret.demoPengurusEmail, 'pengurus@x.test');
      expect(Secret.demoPengelolaIndukEmail, 'induk@x.test');
      expect(Secret.demoCustomerEmail, 'nasabah@x.test');
      expect(Secret.demoNewNasabahEmail, 'baru@x.test');
      expect(Secret.demoSuperadminEmail, 'super@x.test');
    });

    test('the dev environment exposes them, demo login included', () {
      final env = DevEnvironment();

      expect(env.baseUrl, 'http://dev.test');
      // Debug/test builds are not release mode.
      expect(env.supportsDemoLogin, isTrue);
      expect(env.demoPengurusEmail, 'pengurus@x.test');
      expect(env.demoPengelolaIndukEmail, 'induk@x.test');
      expect(env.demoCustomerEmail, 'nasabah@x.test');
      expect(env.demoNewNasabahEmail, 'baru@x.test');
      expect(env.demoSuperadminEmail, 'super@x.test');
    });

    test('the production environment never offers demo accounts', () {
      final env = ProdEnvironment();

      expect(env.baseUrl, 'https://prod.test');
      expect(env.supportsDemoLogin, isFalse);
      expect(env.demoPengurusEmail, '');
      expect(env.demoPengelolaIndukEmail, '');
      expect(env.demoCustomerEmail, '');
      expect(env.demoNewNasabahEmail, '');
      expect(env.demoSuperadminEmail, '');
    });
  });

  group('with an empty .env', () {
    setUp(() => dotenv.loadFromString(envString: '', isOptional: true));

    test('URLs are blank and demo login is off', () {
      expect(Secret.baseUrlDev, '');
      expect(Secret.baseUrlProd, '');
      expect(Secret.demoLoginEnabled, isFalse);
      expect(DevEnvironment().supportsDemoLogin, isFalse);
    });

    test('demo accounts fall back to example addresses', () {
      expect(Secret.demoPengurusEmail, 'pengurus.demo@example.com');
      expect(Secret.demoPengelolaIndukEmail, 'induk.demo@example.com');
      expect(Secret.demoCustomerEmail, 'nasabah.demo@example.com');
      expect(Secret.demoNewNasabahEmail, 'nasabah.baru.demo@example.com');
      expect(Secret.demoSuperadminEmail, 'superadmin.demo@example.com');
    });
  });
}
