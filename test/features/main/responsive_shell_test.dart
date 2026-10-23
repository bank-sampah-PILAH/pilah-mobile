import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/main/presentation/pages/main_page.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_drawer.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_navigation_rail.dart';
import '../../support/auth_support.dart';
import '../../support/nasabah_approval_support.dart';

const _approved = NasabahMembershipEntity(
  id: 'application-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Melati',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Melati',
  status: MembershipStatus.approved,
  isActive: true,
);

/// The lead dev's rule: in the app the navigation sits at the bottom, in a
/// browser it sits on the left. So the shell picks the navigation *family* from
/// the platform, and uses width only to decide how much of the left-hand
/// navigation fits.
///
/// Choosing on width alone was wrong in both directions. A native phone held
/// sideways is wider than 840 and lost its bottom bar; a browser window
/// narrowed below 600 grew one.
void main() {
  Future<GoRouter> mountShell(
    WidgetTester tester, {
    required String role,
    required Size window,
    required bool isWeb,
    String initialLocation = '/home',
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final approval = TestNasabahApprovalNotifier(
        initialState: const NasabahApprovalLoaded([_approved]));

    final state = Authenticated(
      authEntity: AuthEntity(
        name: 'Sari',
        email: 'sari@example.test',
        photoUrl: '',
        token: 'test',
        role: role,
        nextStep: 'dashboard',
      ),
    );
    final auth = authNotifierIn(state);

    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) =>
              MainPage(navigationShell: shell, isWebOverride: isWeb),
          branches: [
            for (final path in [
              '/home',
              '/customers',
              '/prices',
              '/reports',
              '/schedule',
              '/history',
              '/bank',
              '/profile',
              '/pengumuman'
            ])
              StatefulShellBranch(routes: [
                GoRoute(
                    path: path,
                    builder: (_, __) => Center(child: Text('body:$path'))),
              ]),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        nasabahApprovalProvider.overrideWith(() => approval),
        authenticationProvider.overrideWith(() => auth),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  group('the app always keeps its navigation at the bottom', () {
    testWidgets('a phone gets the bottom bar', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: false);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing);
    });

    testWidgets('a tablet keeps the bottom bar', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(820, 1180), isWeb: false);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing,
          reason: 'width must not turn the app into a desktop layout');
    });

    testWidgets('a phone held sideways keeps the bottom bar', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(844, 390), isWeb: false);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing,
          reason: 'this is the landscape bug: 844 is wide, but it is a phone');
    });
  });

  group('the browser always keeps its navigation on the left', () {
    testWidgets('a desktop window uses the rail', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(1440, 900), isWeb: true);
      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'showing both would offer the same menu twice');
    });

    testWidgets('a tablet window uses the rail', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(720, 900), isWeb: true);
      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('a phone browser moves the menu behind a button',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsNothing,
          reason: 'a 256px rail cannot share a 390px window with content');
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'a browser keeps its navigation on the left, not the bottom');
    });
  });

  group('navigating', () {
    testWidgets('the rail moves between branches', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(1440, 900), isWeb: true);
      expect(find.text('body:/home'), findsOneWidget);

      await tester.tap(find.text('Nasabah'));
      await tester.pumpAndSettle();

      expect(find.text('body:/customers'), findsOneWidget);
    });

    testWidgets('the menu button opens a drawer that moves between branches',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(RoleNavigationDrawer), findsOneWidget);

      await tester.tap(find.text('Harga'));
      await tester.pumpAndSettle();

      expect(find.text('body:/prices'), findsOneWidget);
    });

    testWidgets('the mobile drawer matches the sidebar and opens the profile',
        (tester) async {
      final router = await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('PILAH'), findsOneWidget);
      expect(find.text('MENU'), findsOneWidget);
      expect(find.text('Sari'), findsOneWidget);
      expect(find.text('sari@example.test'), findsOneWidget);

      await tester.tap(find.text('Sari'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/profile');
      expect(find.text('body:/profile'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget,
          reason: 'the narrow-browser navigation stays available on profile');
    });

    testWidgets('widening the browser keeps the selected destination',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Harga'));
      await tester.pumpAndSettle();
      expect(find.text('body:/prices'), findsOneWidget);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();

      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(find.text('body:/prices'), findsOneWidget,
          reason: 'a resize must not send the user back to the dashboard');
    });
  });

  /// Review finding from @HeraldoArman on PR #70.
  ///
  /// A staff profile route is branch 7, outside the five navigation
  /// destinations, so `selected` is negative and `main_page.dart` returns the
  /// shell raw. On the app that is exactly right — the bottom bar was never
  /// there. In a browser it means the rail, the drawer and `ContentBounds` all
  /// disappear, leaving a full-bleed page whose only way back is the browser's
  /// own back button.
  ///
  /// The guard itself is older than this PR (`04994da`, PIL-228); what this PR
  /// changed is that there is now left-hand navigation to lose.
  group('tapping the rail profile', () {
    /// How many times the back button has to be pressed to leave the pages
    /// that were pushed. Consumes the stack.
    Future<int> backPresses(WidgetTester tester, GoRouter router) async {
      var presses = 0;
      while (router.canPop() && presses < 10) {
        router.pop();
        await tester.pumpAndSettle();
        presses++;
      }
      return presses;
    }

    testWidgets('opens the profile from another page', (tester) async {
      final router = await mountShell(tester,
          role: 'pengelola', window: const Size(1280, 900), isWeb: true);

      await tester.tap(find.byKey(RoleNavigationRail.profileKey));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/profile');
    });

    testWidgets('does not stack another profile page when already there',
        (tester) async {
      final router = await mountShell(tester,
          role: 'pengelola', window: const Size(1280, 900), isWeb: true);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(RoleNavigationRail.profileKey));
        await tester.pumpAndSettle();
      }

      expect(await backPresses(tester, router), 0,
          reason: 'the profile is a destination of the shell, not a page '
              'pushed over it, so there is nothing to pop');
    });

    testWidgets('opening it keeps the rail and marks no other item',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola',
          window: const Size(1280, 900),
          isWeb: true,
          initialLocation: '/customers');
      expect(
          tester
              .widget<NavigationRail>(find.byType(NavigationRail))
              .selectedIndex,
          1);

      await tester.tap(find.byKey(RoleNavigationRail.profileKey));
      await tester.pumpAndSettle();

      expect(find.byType(RoleNavigationRail), findsOneWidget);
      expect(
          tester
              .widget<NavigationRail>(find.byType(NavigationRail))
              .selectedIndex,
          isNull,
          reason: 'Nasabah must not stay highlighted behind the profile');
    });

    testWidgets('another rail item leads back out of the profile',
        (tester) async {
      final router = await mountShell(tester,
          role: 'pengelola',
          window: const Size(1280, 900),
          isWeb: true,
          initialLocation: '/profile');

      await tester.tap(find.text('Nasabah'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/customers');
    });
  });

  testWidgets('the rail logo returns to the home branch', (tester) async {
    final router = await mountShell(tester,
        role: 'pengelola',
        window: const Size(1280, 900),
        isWeb: true,
        initialLocation: '/customers');
    expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1);

    await tester.tap(find.byKey(RoleNavigationRail.logoKey));
    await tester.pumpAndSettle();

    expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        0);
    expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/home');
  });

  group('a route outside the destinations keeps its navigation on web', () {
    testWidgets('the staff profile keeps the rail on a desktop window',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola',
          window: const Size(1280, 900),
          isWeb: true,
          initialLocation: '/profile');

      expect(find.text('body:/profile'), findsOneWidget);
      expect(find.byType(RoleNavigationRail), findsOneWidget,
          reason: 'losing the whole shell leaves the browser back button as '
              'the only way out of the profile page');
    });

    testWidgets('nothing is marked selected on that route', (tester) async {
      await mountShell(tester,
          role: 'pengelola',
          window: const Size(1280, 900),
          isWeb: true,
          initialLocation: '/profile');

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, isNull,
          reason: 'the pengelola is not on Beranda, so highlighting Beranda '
              'would misreport where they are');
    });

    testWidgets('a narrow browser keeps the menu button', (tester) async {
      await mountShell(tester,
          role: 'pengelola',
          window: const Size(390, 844),
          isWeb: true,
          initialLocation: '/profile');

      expect(find.byIcon(Icons.menu), findsOneWidget,
          reason: 'the drawer is the narrow-browser form of the same shell');
    });

    testWidgets('the app is left exactly as it was', (tester) async {
      await mountShell(tester,
          role: 'pengelola',
          window: const Size(390, 844),
          isWeb: false,
          initialLocation: '/profile');

      expect(find.text('body:/profile'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing,
          reason: 'parity with the behaviour before this PR: the bottom bar '
              'was never on the profile route, and web is the only gap');
    });
  });

  group('Pengumuman is a sidebar destination, not a sixth bottom tab', () {
    testWidgets('the rail lists it and opens its branch', (tester) async {
      final router = await mountShell(tester,
          role: 'pengelola', window: const Size(1280, 900), isWeb: true);

      await tester.tap(find.text('Pengumuman'));
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/pengumuman');
      expect(find.byType(NavigationRail), findsOneWidget,
          reason: 'the rail stays while the page is open');
    });

    testWidgets('the app keeps five bottom tabs', (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: false);

      final bar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bar.items.length, 5);
      expect(find.text('Pengumuman'), findsNothing);
    });

    testWidgets('on the app the page opens without a bottom bar or a dead end',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola',
          window: const Size(390, 844),
          isWeb: false,
          initialLocation: '/pengumuman');

      expect(find.text('body:/pengumuman'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });

  /// Guards the shared-helper extraction asked for in the same review: the
  /// fallback was only covered on the rail side, so the drawer could have
  /// drifted silently.
  group('both navigation headers name the bank sampah the same way', () {
    testWidgets('the drawer falls back when the name is missing',
        (tester) async {
      await mountShell(tester,
          role: 'pengelola', window: const Size(390, 844), isWeb: true);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Bank Sampah'), findsOneWidget,
          reason: 'the session in this test carries no bankSampahNama');
    });
  });
}
