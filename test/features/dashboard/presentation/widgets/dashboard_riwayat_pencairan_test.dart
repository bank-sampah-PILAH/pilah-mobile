import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_page.dart';

void main() {
  testWidgets('opens the riwayat pencairan of the whole bank', (tester) async {
    var opened = false;
    Object? extra = 'not set';
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const Scaffold(body: Center(child: DashboardActionButtons())),
        ),
        GoRoute(
          path: RiwayatPencairanPage.route,
          builder: (context, state) {
            opened = true;
            extra = state.extra;
            return const Scaffold(body: Text('riwayat'));
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Riwayat Pencairan'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(extra, isNull);
  });
}
