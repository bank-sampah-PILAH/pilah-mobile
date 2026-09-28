import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

void main() {
  testWidgets('opens the Nasabah tab and then the add form', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: DashboardActionButtons()),
          routes: [
            GoRoute(
              path: 'nasabah',
              builder: (_, __) => const Scaffold(body: Text('Daftar Nasabah')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Tambah\nNasabah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Nasabah'), findsOneWidget);
    expect(find.text('Tambah Nasabah'), findsOneWidget);
  });

  testWidgets('opens setoran and payout history routes', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: DashboardActionButtons()),
        ),
        GoRoute(
          path: TransaksiBaruPage.route,
          builder: (_, __) => const Scaffold(body: Text('Form Setoran')),
        ),
        GoRoute(
          path: RiwayatPencairanPage.route,
          builder: (_, __) => const Scaffold(body: Text('Daftar Pencairan')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('Setoran Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Form Setoran'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Riwayat Pencairan'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Pencairan'), findsOneWidget);
  });
}
