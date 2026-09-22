import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/complete_profile_screen.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockDataSource extends Mock implements OnboardingRemoteDataSource {}

Future<void> _pumpScreen(WidgetTester tester, AuthEntity account) async {
  final auth = _MockAuthBloc();
  whenListen(
    auth,
    const Stream<AuthenticationStates>.empty(),
    initialState: Authenticated(authEntity: account),
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>.value(value: auth),
        BlocProvider<OnboardingCubit>.value(
          value: OnboardingCubit(_MockDataSource()),
        ),
      ],
      child: const MaterialApp(home: CompleteProfileScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  testWidgets(
      'prefills nama, no_hp and alamat from the saved profile when no wizard draft exists',
      (tester) async {
    await _pumpScreen(
      tester,
      const AuthEntity(
        id: 'user-1',
        name: 'Nasabah PILAH',
        email: 'nasabah@example.com',
        photoUrl: '',
        token: 'jwt',
        nextStep: 'complete_profile',
        role: 'nasabah',
        noHp: '81234567890',
        alamat: 'Jl. Melati No. 5',
      ),
    );

    expect(find.text('Nasabah PILAH'), findsOneWidget);
    expect(find.text('81234567890'), findsOneWidget);
    expect(find.text('Jl. Melati No. 5'), findsOneWidget);
  });

  testWidgets('does not prefill alamat for a pengelola account',
      (tester) async {
    await _pumpScreen(
      tester,
      const AuthEntity(
        id: 'user-1',
        name: 'Pengelola PILAH',
        email: 'pengelola@example.com',
        photoUrl: '',
        token: 'jwt',
        nextStep: 'complete_profile',
        role: 'pengelola',
        alamat: 'Jl. Melati No. 5',
      ),
    );

    // The field isn't even shown for this role, so the saved value must not
    // leak in anywhere on screen.
    expect(find.text('Jl. Melati No. 5'), findsNothing);
  });
}
