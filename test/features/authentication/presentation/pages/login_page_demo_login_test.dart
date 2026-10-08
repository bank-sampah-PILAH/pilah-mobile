import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/welcome_card.dart';

class _MockAuthBloc extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

void main() {
  late _MockAuthBloc auth;

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

  testWidgets('shows the demo login action when enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const LoginPage(debugShowDemoLogin: true),
        ),
      ),
    );

    expect(find.text('Masuk dengan akun demo'), findsOneWidget);
    final googleButton = find.ancestor(
      of: find.text('Masuk dengan Google'),
      matching: find.byType(OutlinedButton),
    );
    final demoButton = find.ancestor(
      of: find.text('Masuk dengan akun demo'),
      matching: find.byType(OutlinedButton),
    );
    expect(
        tester.getSize(demoButton).width, tester.getSize(googleButton).width);
  });

  testWidgets('does not show the demo login action when disabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const LoginPage(debugShowDemoLogin: false),
        ),
      ),
    );

    expect(find.text('Masuk dengan akun demo'), findsNothing);
  });

  testWidgets('uses the desktop layout and shows demo login when enabled',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const LoginPage(debugShowDemoLogin: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final desktopContent = find.byKey(const ValueKey('desktop-login-content'));
    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    expect(find.text('Masuk dengan akun demo'), findsOneWidget);
    expect(tester.getSize(desktopContent).width, 1120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the existing layout on narrow screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthenticationBloc>.value(
          value: auth,
          child: const LoginPage(debugShowDemoLogin: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke akun Anda'), findsNothing);
    expect(find.byType(WelcomeCard), findsOneWidget);
    expect(tester.getSize(find.byType(WelcomeCard)).width, 752);
  });
}
