import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/draft_editor_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/services/di.dart';

void main() {
  tearDown(() => di.reset());

  test('constructs migrated providers from the generated DI graph', () async {
    dotenv.loadFromString(envString: '''
BASE_URL_DEV=https://pilah-be-staging.fly.dev
BASE_URL_PROD=https://backend.run.app
ENABLE_DEMO_LOGIN=false
''');
    configureDependencies(environment: AppKey.devEnv);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(nasabahApprovalProvider), isNotNull);
    expect(container.read(draftEditorProvider), isNotNull);
    expect(container.read(nasabahProvider), isNotNull);
    expect(container.read(profileProvider), isNotNull);
    expect(container.read(riwayatAktivitasProvider), isNotNull);
    expect(container.read(transaksiProvider), isNotNull);
  });

  for (final environment in [AppKey.devEnv, AppKey.prodEnv]) {
    test('bootstraps authentication from the real $environment graph',
        () async {
      dotenv.loadFromString(envString: '''
BASE_URL_DEV=https://pilah-be-staging.fly.dev
BASE_URL_PROD=https://backend.run.app
ENABLE_DEMO_LOGIN=false
''');
      // The same public bootstrap and resolution used by main_* and App.
      configureDependencies(environment: environment);
      expect(di.isRegistered<bool>(), isFalse);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
          container.read(authenticationProvider), isA<AuthenticationInitial>());
    });
  }
}
