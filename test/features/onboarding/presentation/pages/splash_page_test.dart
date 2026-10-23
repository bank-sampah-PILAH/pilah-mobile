import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/splash_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

void main() {
  late InviteTokenStore store;

  setUp(() {
    store = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(store);
  });

  tearDown(() => di.unregister<InviteTokenStore>());

  Future<TestAuthenticationNotifier> open(
    WidgetTester tester, {
    required AuthenticationStates initial,
    List<AuthenticationStates> then = const [],
    String? from,
  }) async {
    final auth = authNotifierIn(initial);
    await pumpRouted(
      tester,
      withAuthenticationProvider(
        auth,
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        SplashPage(from: from),
      ),
      extraRoutes: ['/login', '/dashboard', '/pending-approval', '/nasabah'],
    );
    await tester.pump(const Duration(seconds: 1));
    for (final state in then) {
      auth.setStateForTest(state);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('asks the auth provider to restore the session on start',
      (tester) async {
    final notifier = await open(tester, initial: AuthenticationInitial());

    expect(notifier.calls, contains('checkSession'));
    expect(find.text('PILAH'), findsOneWidget);
    expect(find.text('Sistem Manajemen Bank Sampah'), findsOneWidget);
  });

  testWidgets('a restored session goes to its onboarding destination',
      (tester) async {
    await open(tester, initial: AuthenticationInitial(), then: [
      Authenticated(authEntity: testAuth()),
    ]);

    expect(find.text('route:/dashboard'), findsOneWidget);
  });

  testWidgets('a restored session returns to the page it came from',
      (tester) async {
    await open(tester,
        initial: AuthenticationInitial(),
        from: '/nasabah',
        then: [
          Authenticated(authEntity: testAuth()),
        ]);

    expect(find.text('route:/nasabah'), findsOneWidget);
  });

  testWidgets('a pending bank sampah lands on the review screen',
      (tester) async {
    await open(tester, initial: AuthenticationInitial(), then: [
      Authenticated(
        authEntity: const AuthEntity(
          name: 'Siti',
          email: 's@x.test',
          photoUrl: '',
          token: 't',
          role: 'pengelola',
          nextStep: 'approval_pending',
        ),
      ),
    ]);

    expect(find.text('route:/pending-approval'), findsOneWidget);
  });

  testWidgets('no session goes to login', (tester) async {
    await open(tester,
        initial: AuthenticationInitial(), then: [Unauthenticated()]);

    expect(find.text('route:/login'), findsOneWidget);
  });

  testWidgets('a failed restore goes to login, and only routes once',
      (tester) async {
    await open(tester, initial: AuthenticationInitial(), then: [
      AuthenticationFailure(message: 'x'),
      Authenticated(authEntity: testAuth()),
    ]);

    expect(find.text('route:/login'), findsOneWidget);
  });
}
