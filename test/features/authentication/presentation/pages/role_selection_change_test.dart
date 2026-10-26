import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

/// A Google account that tapped the wrong role and has not finished onboarding
/// (PIL-451): it is signed in, so it reaches the role page without a
/// registration token.
AuthEntity _account(String role, {String nextStep = 'complete_profile'}) =>
    AuthEntity(
      id: 'user-1',
      name: 'Sari',
      email: 'sari@example.com',
      photoUrl: '',
      token: 'jwt-$role',
      role: role,
      nextStep: nextStep,
    );

const _draft = CompleteProfileRequest(
  nama: 'Sari Dewi',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1990-04-17',
  noHp: '81234567890',
);

void main() {
  late TestAuthenticationNotifier auth;
  late ProviderContainer container;

  setUp(() {
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() async {
    container.dispose();
    await di.unregister<InviteTokenStore>();
  });

  Future<void> pumpPage(WidgetTester tester, AuthEntity account) async {
    auth = authNotifierIn(Authenticated(authEntity: account));
    container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      onboardingProvider.overrideWith(() => OnboardingNotifier(
            _MockDataSource(),
          )),
    ]);
    container.read(onboardingProvider.notifier).saveProfileDraft(_draft);
    await pumpRouted(
      tester,
      const RoleSelectionPage(),
      extraRoutes: ['/complete-profile', LoginPage.route],
      wrap: (app) =>
          UncontrolledProviderScope(container: container, child: app),
    );
  }

  testWidgets(
      'a signed-in account still completing its profile can pick another role',
      (tester) async {
    await pumpPage(tester, _account('pengelola'));
    auth.changedAuth = _account('nasabah');

    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(find.text('sari@example.com'), findsOneWidget);
    expect(find.text('Ganti akun'), findsNothing,
        reason: 'the account is already created; leaving goes through logout');
    expect(
      tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'^Pengurus Bank Sampah\.'))),
      isSemantics(isSelected: true),
      reason: 'the role the account has now starts selected',
    );

    await tester.tap(find.text('Nasabah'));
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(auth.calls, contains('changeRole'));
    expect(auth.lastRole, GoogleRegistrationRole.nasabah);
    expect(find.text('route:/complete-profile'), findsOneWidget);
    expect(container.read(onboardingProvider.notifier).hasProfileDraft, isFalse,
        reason: 'a draft typed for the old role must not prefill the new one');
  });

  testWidgets('a refused change says why and keeps the account where it was',
      (tester) async {
    await pumpPage(tester, _account('pengelola'));
    auth.changeRoleError =
        'Peran tidak dapat diganti setelah pendaftaran berjalan.';

    await tester.tap(find.text('Nasabah'));
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));
    await pumpToast(tester);

    expect(find.text('Ganti Peran Gagal'), findsOneWidget);
    expect(find.text('Peran tidak dapat diganti setelah pendaftaran berjalan.'),
        findsOneWidget);
    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(container.read(onboardingProvider.notifier).hasProfileDraft, isTrue);
    await settleToasts(tester);
  });

  testWidgets('an account past the profile step is sent to login',
      (tester) async {
    await pumpPage(
        tester, _account('pengelola', nextStep: 'register_bank_sampah'));
    await tester.pumpAndSettle();

    expect(find.text('route:${LoginPage.route}'), findsOneWidget);
  });
}
