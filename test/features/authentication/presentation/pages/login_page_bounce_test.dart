import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/pump_app.dart';

/// A web session whose role has no web shell is bounced from the router to the
/// login page. Because that redirect tears pages down within one frame, the
/// explanatory toast can only be raised from the page the user lands on
/// (CPBI-21 UAT finding).
void main() {
  setUp(() {
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    WebRoleBounceNotice.reset();
  });

  tearDown(() async {
    await di.unregister<InviteTokenStore>();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    required String location,
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/login',
          // Not const: a const instance is compile-time folded and the
          // constructor line never executes under coverage.
          builder: (_, __) => LoginPage(debugShowDemoLogin: false),
        ),
        for (final path in ['/dashboard', '/home'])
          GoRoute(
            path: path,
            builder: (_, __) => const Scaffold(body: Text('halaman lain')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      withAuthenticationProvider(
        TestAuthenticationNotifier(),
        MaterialApp.router(routerConfig: router),
      ),
    );
    await pumpToast(tester);
  }

  group('a bounced web session sees why it is back at login', () {
    testWidgets('a query flag from the redirect raises the toast',
        (tester) async {
      await pumpLogin(tester, location: '/login?$webRoleBounceFlag=1');

      expect(find.text('Peran Tidak Didukung'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('an armed one-shot raises the toast even without the flag',
        (tester) async {
      WebRoleBounceNotice.arm();
      await pumpLogin(tester, location: '/login');

      expect(find.text('Peran Tidak Didukung'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('an ordinary login shows no toast', (tester) async {
      await pumpLogin(tester, location: '/login');

      expect(find.text('Peran Tidak Didukung'), findsNothing);
      await settleToasts(tester);
    });

    testWidgets('a flagged bounce still clears the armed one-shot',
        (tester) async {
      // The shell arms the flag for this same redirect; the query alone must
      // not leave it armed, or the next ordinary login replays the warning.
      WebRoleBounceNotice.arm();
      await pumpLogin(tester, location: '/login?$webRoleBounceFlag=1');
      await settleToasts(tester);

      await pumpLogin(tester, location: '/login');
      expect(find.text('Peran Tidak Didukung'), findsNothing,
          reason: 'the bounce it described was already shown');
    });
  });
}
