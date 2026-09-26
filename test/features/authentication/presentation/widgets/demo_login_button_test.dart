import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_google_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/demo_login_button.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _AuthenticationEventFake extends Fake implements AuthenticationEvent {}

void main() {
  late _MockAuthBloc auth;

  setUpAll(() {
    registerFallbackValue(_AuthenticationEventFake());
  });

  setUp(() {
    auth = _MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: AuthenticationInitial(),
    );
  });

  tearDown(() async {
    await auth.close();
  });

  testWidgets('signs in with the Pengelola Induk role token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const Scaffold(body: DemoLoginButton()),
        ),
      ),
    );

    await tester.tap(find.text('Masuk dengan akun demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pengelola Induk'));
    await tester.pump();

    final event = verify(() => auth.add(captureAny())).captured.single
        as LoginWithGoogleRequested;
    expect(event.idToken,
        'dev-pengelola-induk:induk.demo@example.com:Pengelola Induk PILAH E2E');
  });

  testWidgets('dispatches the selected seeded account token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const Scaffold(body: DemoLoginButton()),
        ),
      ),
    );

    await tester.tap(find.text('Masuk dengan akun demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nasabah'));
    await tester.pump();

    final event = verify(() => auth.add(captureAny())).captured.single
        as LoginWithGoogleRequested;
    expect(event.email, 'nasabah.demo@example.com');
    expect(event.name, 'Nasabah PILAH E2E');
    expect(
      event.idToken,
      'dev-nasabah:nasabah.demo@example.com:Nasabah PILAH E2E',
    );
  });
}
