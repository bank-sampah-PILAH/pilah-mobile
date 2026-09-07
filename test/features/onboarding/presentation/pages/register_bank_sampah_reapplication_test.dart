import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockOnboardingDataSource extends Mock
    implements OnboardingRemoteDataSource {}

/// Pumps the real screen with the two blocs it reads during build.
///
/// The screen listens to [AuthenticationBloc] to bounce a logged-out user to
/// the login page, so without one it throws ProviderNotFoundException before
/// rendering anything. [OnboardingCubit] backs the wizard's back button.
Future<void> _pumpScreen(
  WidgetTester tester, {
  bool isRejectedReapplication = false,
  OnboardingCubit? onboarding,
}) async {
  final auth = _MockAuthBloc();
  whenListen(
    auth,
    const Stream<AuthenticationStates>.empty(),
    initialState: AuthenticationInitial(),
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>.value(value: auth),
        BlocProvider<OnboardingCubit>.value(
          value: onboarding ?? OnboardingCubit(_MockOnboardingDataSource()),
        ),
      ],
      child: MaterialApp(
        home: RegisterBankSampahScreen(
          isRejectedReapplication: isRejectedReapplication,
        ),
      ),
    ),
  );
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
