import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/complete_profile_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/onboarding_support.dart';
import '../../../../support/auth_support.dart';

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

ProviderContainer _containerWithDraft(OnboardingRemoteDataSource dataSource) {
  final container = buildOnboardingContainer(dataSource);
  container.read(onboardingProvider.notifier).saveProfileDraft(_draft);
  return container;
}

const _draft = CompleteProfileRequest(
  nama: 'Sari Dewi',
  jenisKelamin: 'perempuan',
  tanggalLahir: '1990-04-17',
  noHp: '81234567890',
);

/// An account partway through onboarding. [bankSampahStatus] is what decides
/// whether finishing this form starts a new registration or routes on a verdict
/// only the backend can give.
AuthEntity _account({String? bankSampahStatus, String role = 'pengelola'}) =>
    AuthEntity(
      id: 'user-1',
      name: 'Sari',
      email: 'sari@example.com',
      photoUrl: '',
      token: 'jwt',
      nextStep: 'complete_profile',
      bankSampahStatus: bankSampahStatus,
      role: role,
    );

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ProviderContainer onboarding,
  String? bankSampahStatus,
  String role = 'pengelola',
}) async {
  final auth = authNotifierIn(Authenticated(
    authEntity: _account(bankSampahStatus: bankSampahStatus, role: role),
  ));

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: onboarding,
      child: withAuthenticationProvider(
        auth,
        const MaterialApp(home: CompleteProfileScreen()),
      ),
    ),
  );
  await tester.pump();
}

/// Pumps step one inside a real [GoRouter], so `context.push` has somewhere to
/// go and the pushed route can actually be popped.
///
/// Step two is a stand-in: this is about the navigation and what survives it,
/// not about the registration form.
Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  required ProviderContainer onboarding,
  String? bankSampahStatus,
}) async {
  final auth = authNotifierIn(Authenticated(
    authEntity: _account(bankSampahStatus: bankSampahStatus),
  ));

  final router = GoRouter(
    initialLocation: CompleteProfileScreen.route,
    routes: [
      GoRoute(
        path: CompleteProfileScreen.route,
        builder: (_, __) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/register-bank-sampah',
        builder: (_, __) => const Scaffold(body: Text('STEP TWO')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: onboarding,
      child: withAuthenticationProvider(
        auth,
        MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// Scrolls the submit button into view and taps it.
///
/// The form is taller than the test viewport, so the button starts off-screen
/// and a bare tap silently misses it.
Future<void> _tapContinue(WidgetTester tester) async {
  final button = find.text('Simpan Profil & Lanjut');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  // `any()` needs a real request to hand the matcher.
  setUpAll(() => registerFallbackValue(
        const CompleteProfileRequest(
          nama: '',
          jenisKelamin: '',
          tanggalLahir: '',
          noHp: '',
        ),
      ));

  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  testWidgets('centers profile completion in the desktop onboarding card',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = buildOnboardingContainer(_MockDataSource());
    addTearDown(cubit.dispose);

    await _pumpScreen(tester, onboarding: cubit);

    expect(
      tester
          .getSize(find.byKey(const ValueKey('onboarding-desktop-card')))
          .width,
      OnboardingDesktopCard.desktopWidth,
    );
    expect(tester.takeException(), isNull);
  });

  group('returning to step one', () {
    testWidgets('refills the form from the banked draft', (tester) async {
      final cubit = buildOnboardingContainer(_MockDataSource());
      cubit.read(onboardingProvider.notifier).saveProfileDraft(_draft);
      addTearDown(cubit.dispose);

      await _pumpScreen(tester, onboarding: cubit);

      // The State is rebuilt from scratch on the way back, so anything visible
      // here came from the draft rather than from surviving widget state.
      expect(find.widgetWithText(TextFormField, 'Sari Dewi'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '81234567890'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, '17/04/1990'),
        findsOneWidget,
        reason: 'the draft stores an ISO date for the API; the field has to '
            'show the dd/MM/yyyy the user originally picked',
      );
    });

    testWidgets('leaves the form empty when nothing was banked',
        (tester) async {
      final cubit = buildOnboardingContainer(_MockDataSource());
      addTearDown(cubit.dispose);

      await _pumpScreen(tester, onboarding: cubit);

      expect(find.widgetWithText(TextFormField, 'Sari Dewi'), findsNothing);
    });
  });

  testWidgets(
      'shows the nasabah bank-picker stepper, not the pengelola wording, '
      'for Nasabah', (tester) async {
    final cubit = buildOnboardingContainer(_MockDataSource());
    addTearDown(cubit.dispose);

    await _pumpScreen(tester, onboarding: cubit, role: 'nasabah');

    expect(find.text('Data Bank Sampah'), findsNothing);
    expect(find.text('Pilih Bank Sampah'), findsOneWidget);
    expect(find.text('Profil Diri'), findsOneWidget);
    expect(find.text('Simpan Profil & Lanjut'), findsOneWidget);
  });

  group('the deferred profile call', () {
    testWidgets('is not made when a new bank sampah registration follows',
        (tester) async {
      final dataSource = _MockDataSource();
      // Seeded so the prefill leaves a complete, valid form — this exercises
      // the submit path without having to drive the date picker.
      final cubit = _containerWithDraft(dataSource);
      addTearDown(cubit.dispose);

      // No bank sampah on the account: AuthService.user_state guarantees the
      // next step is register_bank_sampah, so the answer needs no round trip.
      await _pumpRouter(tester, onboarding: cubit, bankSampahStatus: null);

      await _tapContinue(tester);

      expect(find.text('STEP TWO'), findsOneWidget);
      verifyNever(() => dataSource.completeProfile(any()));
      expect(cubit.read(onboardingProvider.notifier).profileDraft?.nama,
          'Sari Dewi');
    });

    testWidgets('leaves step one on the stack, with its input intact',
        (tester) async {
      final dataSource = _MockDataSource();
      final cubit = _containerWithDraft(dataSource);
      addTearDown(cubit.dispose);

      final router = await _pumpRouter(
        tester,
        onboarding: cubit,
        bankSampahStatus: null,
      );

      await _tapContinue(tester);
      expect(find.text('STEP TWO'), findsOneWidget);

      // What "Kembali" and the system back button both do on step two.
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Sari Dewi'),
        findsOneWidget,
        reason: 'the point of deferring the call is that step one stays '
            'editable; coming back to an empty form would defeat it',
      );
      verifyNever(() => dataSource.completeProfile(any()));
    });

    testWidgets(
        'is made immediately when the account already has a bank sampah',
        (tester) async {
      final dataSource = _MockDataSource();
      when(() => dataSource.completeProfile(any())).thenAnswer(
        (_) async => const OnboardingResult(nextStep: 'approval_pending'),
      );
      final cubit = _containerWithDraft(dataSource);
      addTearDown(cubit.dispose);

      // A pending registration means the destination is the backend's verdict,
      // not a new registration form — so there is nothing to defer for.
      await _pumpRouter(
        tester,
        onboarding: cubit,
        bankSampahStatus: 'pending',
      );

      await _tapContinue(tester);

      verify(() => dataSource.completeProfile(any())).called(1);
    });
  });
}
