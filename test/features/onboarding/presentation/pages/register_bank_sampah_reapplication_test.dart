import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';

import '../../../../support/onboarding_support.dart';
import '../../../../support/auth_support.dart';

class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

/// Pumps the real screen with the two blocs it reads during build.
///
/// The screen listens to [AuthenticationBloc] to bounce a logged-out user to
/// the login page, so without one it throws ProviderNotFoundException before
/// rendering anything. The onboarding provider backs the wizard's back button.
Future<void> _pumpScreen(
  WidgetTester tester, {
  bool isRejectedReapplication = false,
}) async {
  final auth = authNotifierIn(AuthenticationInitial());

  await tester.pumpWidget(
    withOnboarding(
      withAuthenticationProvider(
        auth,
        MaterialApp(
          home: RegisterBankSampahScreen(
            isRejectedReapplication: isRejectedReapplication,
          ),
        ),
      ),
      _MockOnboardingDataSource(),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('RegisterBankSampahScreen re-application mode', () {
    testWidgets(
        'shows the rejection banner and hides the stepper when rejected',
        (tester) async {
      await _pumpScreen(tester, isRejectedReapplication: true);

      // Banner present with the required copy.
      expect(find.text('Pendaftaran Ditolak'), findsOneWidget);
      expect(
        find.textContaining('Pendaftaran sebelumnya ditolak'),
        findsOneWidget,
      );
      // Stepper gone (its labels are unique to the stepper).
      expect(find.text('Data Bank Sampah'), findsNothing);
      // The form itself is unchanged and present (submit button is a plain
      // Text; the field labels are RichText, which find.text can't match).
      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    });

    testWidgets('shows the stepper and no banner in normal (first-time) mode',
        (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Data Bank Sampah'), findsOneWidget); // stepper label
      expect(find.text('Pendaftaran Ditolak'), findsNothing);
      // Same form in both modes.
      expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
    });

    testWidgets('centers the complete flow in a login-width card on desktop', (
      tester,
    ) async {
      _setViewport(tester, const Size(1440, 1200));
      await _pumpScreen(tester);

      final card = find.byKey(const ValueKey('onboarding-desktop-card'));
      expect(tester.getSize(card).width, OnboardingDesktopCard.desktopWidth);
      expect(tester.getRect(card).center.dx, 720);
      expect(
        tester.getSize(find.byType(OnboardingHeader)).width,
        OnboardingDesktopCard.desktopWidth - 2,
      );
      expect(
        tester.getSize(find.byType(OnboardingStepper)).width,
        OnboardingDesktopCard.desktopWidth - 2,
      );
    });

    testWidgets('keeps the existing full-width layout on narrow screens', (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await _pumpScreen(tester);

      expect(
        find.byKey(const ValueKey('onboarding-desktop-card')),
        findsNothing,
      );
      expect(tester.getSize(find.byType(OnboardingHeader)).width, 390);
      expect(tester.getSize(find.byType(OnboardingStepper)).width, 390);
    });

    testWidgets('offers a way back to step one in both modes', (tester) async {
      await _pumpScreen(tester, isRejectedReapplication: true);

      expect(
        find.text('Kembali'),
        findsOneWidget,
        reason: 'the wizard is only navigable if step two can return to step '
            'one; a re-application has the same button, it just has no pushed '
            'route to pop back to',
      );
    });
  });
}
