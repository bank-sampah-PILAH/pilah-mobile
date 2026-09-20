import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/register_google_role_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/role_selection_page.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _FakeAuthEvent extends Fake implements AuthenticationEvent {}

void main() {
  late _MockAuthBloc auth;
  final registration = GoogleRegistrationRequired(
    registrationToken: 'signed-token',
    expiresIn: 600,
    name: 'Ayu Lestari',
    email: 'ayu@example.com',
    photoUrl: 'https://example.com/ayu.png',
  );

  setUpAll(() => registerFallbackValue(_FakeAuthEvent()));

  setUp(() {
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: GoogleRegistrationPending(registration: registration),
    );
  });

  tearDown(() async => auth.close());

  testWidgets('offers three non-Superadmin roles and submits the selection',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const RoleSelectionPage(),
        ),
      ),
    );

    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(find.text('Langkah 1'), findsOneWidget);
    expect(find.text('ayu@example.com'), findsOneWidget);
    expect(find.text('Nasabah'), findsOneWidget);
    expect(find.text('Pengelola Bank Sampah'), findsOneWidget);
    expect(find.text('Pengelola Bank Sampah Induk'), findsOneWidget);
    expect(find.text('Superadmin'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Nasabah'));
    await tester.pump();
    await tester.tap(find.text('Lanjutkan'));

    verify(() => auth.add(
          const RegisterGoogleRoleRequested(role: 'nasabah'),
        )).called(1);
  });
}
