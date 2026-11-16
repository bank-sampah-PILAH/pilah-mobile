import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/draft_pencairan_routes.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_args.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/pilih_nasabah_pencairan_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';

import '../../../support/app_shell_support.dart';
import '../../../support/stub_api.dart';

/// The active route list keeps the editor safe to reach: it refuses a link
/// that names no draft, by `?id=` or by `extra`.
void main() {
  late StubApi api;
  late AppShell shell;

  setUp(() async {
    api = StubApi();
    shell = AppShell(api);
    await shell.registerDi();
    shell.signedInAsRole('pengelola', bankStatus: 'active');
    api.on('GET', '/api/v1/draft-pencairan',
        json: {'count': 0, 'next': null, 'results': []});
  });

  tearDown(() => shell.unregisterDi());

  /// The feature's own routes as they were, plus a stand-in for the dashboard.
  Future<GoRouter> mountRoutes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('dashboard')),
        ),
        ...draftPencairanRoutes,
      ],
    );
    addTearDown(router.dispose);
    await tester
        .pumpWidget(shell.wrap(MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    return router;
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('the list and the nasabah picker open on their own paths',
      (tester) async {
    final router = await mountRoutes(tester);

    router.go(DraftListPage.route);
    await tester.pumpAndSettle();
    expect(find.byType(DraftListPage), findsOneWidget);

    router.go(PilihNasabahPencairanPage.route);
    await tester.pumpAndSettle();
    expect(find.byType(PilihNasabahPencairanPage), findsOneWidget);
  });

  testWidgets('the editor needs a draft and otherwise falls back to the list',
      (tester) async {
    final router = await mountRoutes(tester);

    router.go(DraftEditorPage.route);
    await tester.pumpAndSettle();
    expect(find.byType(DraftEditorPage), findsNothing);
    expect(locationOf(router), DraftListPage.route);

    router.go(
      DraftEditorPage.route,
      extra: const DraftEditorArgs.baru([
        Kandidat(id: 'n-1', kode: 'NAS-1', nama: 'Ahmad', saldo: 1000),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DraftEditorPage), findsOneWidget);
  });

  test('the draft routes stay in their user flow order', () {
    expect(
      draftPencairanRoutes.map((route) => route.path),
      [
        DraftListPage.route,
        PilihNasabahPencairanPage.route,
        DraftEditorPage.route,
      ],
      reason: 'the router registers this list so the flow cannot drift',
    );
  });
}
