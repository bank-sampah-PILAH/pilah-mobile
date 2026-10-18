import 'dart:async';

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
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/post_login_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

void main() {
  late MockAuthBloc auth;
  late StreamController<AuthenticationStates> states;

  setUpAll(() {
    registerFallbackValue(const PostLoginEvent(email: '', password: ''));
  });

  setUp(() {
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    states = StreamController<AuthenticationStates>.broadcast();
    auth = MockAuthBloc();
    whenListen(auth, states.stream, initialState: AuthenticationInitial());
  });

  tearDown(() async {
    await di.unregister<InviteTokenStore>();
    unawaited(states.close());
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) =>
      pumpRouted(
        tester,
        const LoginPage(debugShowDemoLogin: false),
        extraRoutes: [
          '/dashboard',
          '/superadmin-dashboard',
          '/pengelola-induk-dashboard',
        ],
        wrap: (app) =>
            BlocProvider<AuthenticationBloc>.value(value: auth, child: app),
        size: size,
      );

  Future<void> enterCredentials(WidgetTester tester) async {
    await tester.enterText(
        find.byKey(const ValueKey('login-email-field')), 'ayu@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('login-password-field')), 'correct horse');
  }

  Future<void> tapEmailSignIn(WidgetTester tester) async {
    final button = find.text('Masuk dengan Email');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('keeps Google first and provides an email/password form below it',
      (tester) async {
    await pumpPage(tester);

    final google = find.text('Masuk dengan Google');
    final divider = find.text('ATAU');
    final email = find.byKey(const ValueKey('login-email-field'));
    final password = find.byKey(const ValueKey('login-password-field'));

    expect(google, findsOneWidget);
    expect(divider, findsOneWidget);
    expect(email, findsOneWidget);
    expect(password, findsOneWidget);
    expect(
      tester.getTopLeft(google).dy,
      lessThan(tester.getTopLeft(divider).dy),
    );
    expect(
      tester.getTopLeft(divider).dy,
      lessThan(tester.getTopLeft(email).dy),
    );
    expect(find.text('Daftar dengan email'), findsNothing);
  });

  testWidgets('submits email credentials through the auth bloc',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    await tapEmailSignIn(tester);

    final event =
        verify(() => auth.add(captureAny())).captured.single as PostLoginEvent;
    expect(event.email, 'ayu@example.com');
    expect(event.password, 'correct horse');
  });

  testWidgets('shows the shared loading state on the email action',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    states.add(AuthenticationLoading());
    await tester.pump();

    expect(find.text('Masuk dengan Email'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('login-email-submit')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the email form available in the desktop layout',
      (tester) async {
    await pumpPage(tester, size: const Size(1440, 900));

    expect(find.byKey(const ValueKey('desktop-login-content')), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password-field')), findsOneWidget);
    expect(find.text('Masuk dengan Email'), findsOneWidget);
  });

  testWidgets('email sign-in success uses the existing authenticated route',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    await tapEmailSignIn(tester);
    verify(() => auth.add(any())).called(1);

    states.add(Authenticated(
      authEntity: AuthEntity(
        id: 'u1',
        name: 'Ayu',
        email: 'ayu@example.com',
        photoUrl: '',
        token: 'access-token',
        role: 'pengelola_induk',
        nextStep: 'pengelola_induk_dashboard',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('route:/pengelola-induk-dashboard'), findsOneWidget);
  });

  testWidgets('shows a generic login error after a rejected email sign-in',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    await tapEmailSignIn(tester);

    states.add(AuthenticationFailure(message: 'Email atau kata sandi salah'));
    await pumpToast(tester);

    expect(find.text('Login Gagal'), findsOneWidget);
    expect(find.text('Email atau kata sandi salah'), findsOneWidget);
    await settleToasts(tester);
  });
}
