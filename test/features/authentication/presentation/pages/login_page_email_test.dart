import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

void main() {
  late TestAuthenticationNotifier auth;

  setUp(() {
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    auth = TestAuthenticationNotifier();
  });

  tearDown(() async {
    await di.unregister<InviteTokenStore>();
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
        wrap: (app) => ProviderScope(
          overrides: [authenticationProvider.overrideWith(() => auth)],
          child: app,
        ),
        size: size,
      );

  Future<void> enterCredentials(WidgetTester tester) async {
    await tester.enterText(
        find.byKey(const ValueKey('login-email-field')), 'ayu@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('login-password-field')), 'correct horse');
  }

  String fieldValue(WidgetTester tester, String key) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

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

    expect(auth.lastEmail, 'ayu@example.com');
    expect(auth.lastPassword, 'correct horse');
  });

  testWidgets('submits credentials when Done is pressed in the password field',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(auth.lastEmail, 'ayu@example.com');
    expect(auth.lastPassword, 'correct horse');
  });

  testWidgets('shows the shared loading state on the email action',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    auth.setStateForTest(AuthenticationLoading());
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

  testWidgets(
      'preserves credentials when resizing across the layout breakpoint',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();
    expect(fieldValue(tester, 'login-email-field'), 'ayu@example.com');
    expect(fieldValue(tester, 'login-password-field'), 'correct horse');

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(fieldValue(tester, 'login-email-field'), 'ayu@example.com');
    expect(fieldValue(tester, 'login-password-field'), 'correct horse');
  });

  testWidgets('email sign-in success uses the existing authenticated route',
      (tester) async {
    await pumpPage(tester);
    await enterCredentials(tester);
    await tapEmailSignIn(tester);
    expect(auth.calls, contains('postLogin'));

    auth.setStateForTest(Authenticated(
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

    auth.setStateForTest(
      AuthenticationFailure(message: 'Email atau kata sandi salah'),
    );
    await pumpToast(tester);

    expect(find.text('Login Gagal'), findsOneWidget);
    expect(find.text('Email atau kata sandi salah'), findsOneWidget);
    await settleToasts(tester);
  });
}
