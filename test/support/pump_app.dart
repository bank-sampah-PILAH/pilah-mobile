import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';

/// Pumps [home] inside a `MaterialApp.router` so widgets that call
/// `context.pop()` / `context.push()` work. Extra [routes] can be registered to
/// observe navigation; each renders its path as text. With [pushed], [home] is
/// pushed on top of a root page so it has somewhere to pop back to.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget home, {
  List<String> extraRoutes = const [],
  Widget Function(Widget child)? wrap,
  Size? size,
  bool pushed = false,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final router = GoRouter(
    // The app's root key, so `AppNotification.afterNavigation` finds a navigator.
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            pushed ? const Scaffold(body: Text('route:/')) : home,
      ),
      if (pushed) GoRoute(path: '/page', builder: (_, __) => home),
      for (final path in extraRoutes)
        GoRoute(
          path: path,
          builder: (_, __) => Scaffold(body: Text('route:$path')),
        ),
    ],
  );
  addTearDown(router.dispose);
  final app = MaterialApp.router(routerConfig: router);
  await tester.pumpWidget(wrap == null ? app : wrap(app));
  await tester.pump();
  if (pushed) {
    router.push('/page');
    await tester.pumpAndSettle();
  }
  return router;
}

/// Lets an in-flight action finish and the toast it raises slide in, without
/// running the toast's auto-dismiss timer (which `pumpAndSettle` would).
Future<void> pumpToast(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Runs any toast's auto-dismiss timer out so no timer is pending at the end.
Future<void> settleToasts(WidgetTester tester) async {
  // In steps: a toast's dismiss timer only starts once its slide-in has
  // finished, so one long jump would leave that timer still pending.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
  await tester.pumpAndSettle();
}

/// Lets real asynchronous work (file I/O, which fake-async cannot advance) run
/// to completion, interleaving frames so the UI reacts to each result.
Future<void> pumpReal(WidgetTester tester, {int rounds = 6}) async {
  for (var i = 0; i < rounds; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps (letting real I/O run between frames) until [finder] matches, or fails
/// after [limit] rounds. For flows that mix fake-async timers with file I/O.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder,
    {int limit = 60}) async {
  for (var i = 0; i < limit && finder.evaluate().isEmpty; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
