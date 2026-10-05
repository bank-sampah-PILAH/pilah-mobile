import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps [home] inside a `MaterialApp.router` so widgets that call
/// `context.pop()` / `context.push()` work. Extra [routes] can be registered to
/// observe navigation; each renders its path as text.
Future<GoRouter> pumpRouted(
  WidgetTester tester,
  Widget home, {
  List<String> extraRoutes = const [],
  Widget Function(Widget child)? wrap,
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
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
  return router;
}

/// Lets an in-flight action finish and the toast it raises slide in, without
/// running the toast's auto-dismiss timer (which `pumpAndSettle` would).
Future<void> pumpToast(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 1));
}

/// Runs any toast's auto-dismiss timer out so no timer is pending at the end.
Future<void> settleToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpAndSettle();
}
