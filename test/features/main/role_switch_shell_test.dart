import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/pages/nasabah_page.dart';

import '../../support/app_shell_support.dart';
import '../../support/stub_api.dart';

void main() {
  late AppShell shell;
  late StubApi api;

  setUp(() async {
    api = StubApi();
    shell = AppShell(api);
    await shell.registerDi();
  });

  tearDown(() => shell.unregisterDi());

  testWidgets('switching the active role leaves no page of the previous role',
      (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on('GET', '/api/v1/dashboard/stats', json: <String, dynamic>{});
    api.on('GET', '/api/v1/transaksi', json: {'results': []});
    api.on('GET', '/api/v1/pencairan',
        json: {'count': 0, 'next': null, 'results': []});

    shell.signedInAsRole('pengelola', bankStatus: 'active');
    final router = AppRouterConfig.getRouter();
    await tester.pumpWidget(shell.wrap(Consumer(
      builder: (context, ref, _) {
        ref.listen(authenticationProvider,
            (_, __) => AppRouterConfig.notifyAuthStateChanged());
        return MaterialApp.router(routerConfig: router);
      },
    )));
    router.go(NasabahPage.route);
    await tester.pumpAndSettle();
    expect(find.byType(NasabahPage), findsOneWidget);

    shell.signedInAsRole('nasabah', step: 'nasabah_dashboard');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path,
        AppLocations.dashboard);
    // The shell is an IndexedStack, so every branch the previous role visited
    // stays mounted behind the one on screen. Offstage is still in the app:
    // the staff list would sit there holding that bank's nasabah, now behind
    // a session that is no longer a pengurus.
    expect(find.byType(NasabahPage, skipOffstage: false), findsNothing);
  });
}
