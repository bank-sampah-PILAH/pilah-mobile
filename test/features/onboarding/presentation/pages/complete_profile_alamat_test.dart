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

AuthEntity _account(String role) => AuthEntity(
      id: 'user-1',
      name: 'Test User',
      email: 'user@example.com',
      photoUrl: '',
      token: 'jwt',
      nextStep: 'complete_profile',
      role: role,
    );

Future<void> _pumpScreen(WidgetTester tester, {required String role}) async {
  final auth = _MockAuthBloc();
  whenListen(
    auth,
    const Stream<AuthenticationStates>.empty(),
    initialState: Authenticated(authEntity: _account(role)),
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

// The form field labels are RichText built directly (not Text.rich), so
// find.text can't match them — the hint text is what's actually findable,
// and it's unique to this field.
final _alamatHint =
    find.text('Jl. Nama Jalan, RT/RW, Kelurahan,\nKecamatan, Kota');

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  testWidgets('shows the alamat field for a nasabah account', (tester) async {
    await _pumpScreen(tester, role: 'nasabah');

    expect(_alamatHint, findsOneWidget);
  });

  testWidgets('hides the alamat field for a pengelola account', (tester) async {
    await _pumpScreen(tester, role: 'pengelola');

    expect(_alamatHint, findsNothing);
  });

  testWidgets('hides the alamat field for a pengelola induk account',
      (tester) async {
    await _pumpScreen(tester, role: 'pengelola_induk');

    expect(_alamatHint, findsNothing);
  });

  testWidgets(
      "labels step 2 'Pilih Bank Sampah' for a nasabah account, not the "
      'pengelola wording', (tester) async {
    await _pumpScreen(tester, role: 'nasabah');

    expect(find.text('Pilih Bank Sampah'), findsOneWidget);
    expect(find.text('Data Bank Sampah'), findsNothing);
  });

  testWidgets("labels step 2 'Data Bank Sampah' for a pengelola account",
      (tester) async {
    await _pumpScreen(tester, role: 'pengelola');

    expect(find.text('Data Bank Sampah'), findsOneWidget);
    expect(find.text('Pilih Bank Sampah'), findsNothing);
  });
}
