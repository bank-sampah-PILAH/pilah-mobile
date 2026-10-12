import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
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

  Future<GoRouter> pumpChooser(WidgetTester tester) async {
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
          path: DraftListPage.route,
          builder: (_, __) => const Scaffold(body: Text('Daftar Pencairan')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Transaksi Baru'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('offers a choice between Catat Setoran and Pencairan',
      (tester) async {
    await pumpChooser(tester);

    expect(find.text('Catat Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
  });

  testWidgets('opens Setoran Baru when Catat Setoran is chosen',
      (tester) async {
    await pumpChooser(tester);

    await tester.tap(find.text('Catat Setoran'));
    await tester.pumpAndSettle();

    expect(find.text('Form Setoran'), findsOneWidget);
  });

  testWidgets('opens the pencairan list when Pencairan is chosen',
      (tester) async {
    await pumpChooser(tester);

    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Pencairan'), findsOneWidget);
  });
}
