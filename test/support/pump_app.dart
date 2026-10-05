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
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}
