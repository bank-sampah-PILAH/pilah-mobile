import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/go.dart';

void main() {
  testWidgets('getLocation reports the current route with its query',
      (tester) async {
    String? seen;
    final router = GoRouter(
      initialLocation: '/riwayat?keanggotaan_id=42',
      routes: [
        GoRoute(
          path: '/riwayat',
          builder: (context, _) {
            seen = Go.getLocation(context);
            return const SizedBox();
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(seen, '/riwayat?keanggotaan_id=42');
    // The class is a plain namespace; make sure it can still be instantiated.
    // ignore: unused_local_variable
    final go = Go();
  });
}
