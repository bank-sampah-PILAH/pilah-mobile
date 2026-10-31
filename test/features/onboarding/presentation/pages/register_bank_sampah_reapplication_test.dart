import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_flow_layout.dart';

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

    for (final size in [
      const Size(1440, 900),
      const Size(768, 1024),
      const Size(375, 812)
    ]) {
      testWidgets('adapts registration and reapplication at ${size.width}px',
          (tester) async {
        _setViewport(tester, size);
        await _pumpScreen(tester);

        final desktop = size.width >= 840;
        expect(find.byKey(const ValueKey('onboarding-sidebar')),
            desktop ? findsOneWidget : findsNothing);
        final form = tester
            .getRect(find.byKey(const ValueKey('onboarding-form-surface')));
        expect(form.width, lessThanOrEqualTo(880));
        expect(form.left, greaterThanOrEqualTo(0));
        expect(form.right, lessThanOrEqualTo(size.width));
        final pair = tester
            .widget<OnboardingFieldPair>(find.byType(OnboardingFieldPair));
        final details = tester.getRect(find.byWidget(pair.first));
        final photo = tester.getRect(find.byWidget(pair.second));
        if (size.width >= 600) {
          expect(photo.left, greaterThan(details.right));
        } else {
          expect(photo.top, greaterThanOrEqualTo(details.bottom));
        }
        final actions =
            tester.getRect(find.byKey(const ValueKey('onboarding-actions')));
        expect(actions.bottom, size.height);
        await tester.tap(find.text('Ajukan Pendaftaran'));
        await tester.pump();
        expect(find.text('Nama minimal 3 karakter'), findsOneWidget);
        expect(find.text('Foto kegiatan wajib diunggah'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _pumpScreen(tester, isRejectedReapplication: true);
        expect(find.text('Pendaftaran Ditolak'), findsOneWidget);
        expect(find.byType(OnboardingProgress), findsNothing);
        expect(find.text('Ajukan Pendaftaran'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('preserves entered bank data when the window is resized',
        (tester) async {
      _setViewport(tester, const Size(1440, 900));
      await _pumpScreen(tester);
      await tester.enterText(
          find.byType(TextFormField).first, 'Bank Sampah Demo');
      tester.view.physicalSize = const Size(375, 812);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Bank Sampah Demo'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reveals the first error after submitting from the bottom',
        (tester) async {
      _setViewport(tester, const Size(375, 812));
      await _pumpScreen(tester);
      await tester.drag(find.byKey(const ValueKey('onboarding-content-scroll')),
          const Offset(0, -800));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Pendaftaran'));
      await tester.pumpAndSettle();
      final error = tester.getRect(find.text('Nama minimal 3 karakter'));
      expect(error.top, greaterThan(56));
      expect(
          error.bottom,
          lessThan(tester
              .getRect(find.byKey(const ValueKey('onboarding-actions')))
              .top));
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
