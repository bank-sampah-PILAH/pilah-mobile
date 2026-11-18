import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_detail_page.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_form_page.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_page.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pengumuman_routes.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/nasabah_pengumuman_provider.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/providers/pengumuman_provider.dart';

import '../../../support/auth_support.dart';
import '../../../support/pengumuman_support.dart';
import '../../../support/stub_api.dart';

/// The route-level guards PIL-436 took out of the live router.
///
/// While Pengumuman is locked these routes are not registered, so nothing else
/// exercises their `redirect`s. They are the wiring that made the pages safe to
/// reach — a stale `/pengumuman/detail` link with no row behind it, a form with
/// no args, a nasabah with two banks needing `keanggotaan_id` to avoid a 422 —
/// and re-enabling the feature means registering them again. Pinning them here
/// keeps them compiled and tested instead of only recoverable from git history.
void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    api.on('GET', '/api/v1/nasabah/me/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
  });

  /// The locked routes plus a stand-in for the dashboard they fall back to.
  Future<GoRouter> mountRoutes(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('dashboard')),
        ),
        ...pengumumanRoutes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authenticationProvider.overrideWith(
          () => authNotifierIn(
            Authenticated(authEntity: testAuth(role: 'nasabah')),
          ),
        ),
        nasabahPengumumanProvider.overrideWith(
          () => NasabahPengumumanNotifier(
            NasabahPengumumanRepository(api.network),
          ),
        ),
        pengumumanProvider.overrideWith(
          () => PengumumanNotifier(buildPengumumanRepository(api)),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('the list reads keanggotaan_id from the query', (tester) async {
    final router = await mountRoutes(tester);

    router.go('/pengumuman?keanggotaan_id=m1');
    await tester.pumpAndSettle();

    expect(
      tester.widget<PengumumanPage>(find.byType(PengumumanPage)).membershipId,
      'm1',
      reason: 'a nasabah with two banks gets a 422 without this scoping',
    );
  });

  testWidgets('the detail needs its row and otherwise falls back to the list',
      (tester) async {
    final router = await mountRoutes(tester);

    router.go('/pengumuman/detail');
    await tester.pumpAndSettle();
    expect(find.byType(PengumumanDetailPage), findsNothing);
    expect(locationOf(router), '/pengumuman');

    router.go(
      '/pengumuman/detail',
      extra: const PengumumanEntity(
        id: 'p1',
        bankSampahId: 'b1',
        judul: 'Jemputan',
        isi: 'Isi',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PengumumanDetailPage), findsOneWidget);
  });

  testWidgets('the form needs its args and otherwise falls back',
      (tester) async {
    final router = await mountRoutes(tester);

    router.go('/pengumuman/kelola/ubah');
    await tester.pumpAndSettle();
    expect(find.byType(PengumumanFormPage), findsNothing);
    expect(locationOf(router), '/dashboard');

    router.go('/pengumuman/kelola/ubah', extra: const PengumumanFormArgs());
    await tester.pumpAndSettle();
    expect(find.byType(PengumumanFormPage), findsOneWidget);
  });

  test('the locked paths are derived from these routes, never retyped', () {
    expect(
      pengumumanRoutes.map((route) => route.path),
      [
        PengumumanPage.route,
        PengumumanDetailPage.route,
        PengumumanFormPage.route,
      ],
      reason: 'app_router_config builds its redirects from this list, so the '
          'locked paths cannot drift from the real ones',
    );
  });
}
