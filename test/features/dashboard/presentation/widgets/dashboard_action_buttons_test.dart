import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

void main() {
  testWidgets('two main buttons, side by side, and no Pengumuman entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: DashboardActionButtons()),
    ));

    expect(find.text('Transaksi Baru'), findsOneWidget);
    expect(find.text('Tambah Nasabah'), findsOneWidget);
    expect(find.text('Pengumuman'), findsNothing,
        reason:
            'Pengumuman is a navigation destination, not a dashboard button');
    expect(tester.getTopLeft(find.text('Transaksi Baru')).dy,
        tester.getTopLeft(find.text('Tambah Nasabah')).dy);
    expect(tester.takeException(), isNull);
  });

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

    await tester.tap(find.textContaining('Tambah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Nasabah'), findsOneWidget);
    expect(find.textContaining('Tambah'), findsOneWidget);
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

  testWidgets('offers Catat Setoran and Pencairan choices', (tester) async {
    await pumpChooser(tester);

    expect(find.text('Catat Setoran'), findsOneWidget);
    // The dialog entry, not anything behind the barrier. A wide window gets a
    // dialog, not a sheet as wide as the window.
    expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Pencairan'),
        ),
        findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    final payoutChoice = find
        .ancestor(
          of: find.text('Pencairan'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.widget<InkWell>(payoutChoice).onTap, isNotNull);
  });

  testWidgets('on a phone the choice is still a bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpChooser(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('opens Setoran Baru when Catat Setoran is chosen',
      (tester) async {
    await pumpChooser(tester);

    await tester.tap(find.text('Catat Setoran'));
    await tester.pumpAndSettle();

    expect(find.text('Form Setoran'), findsOneWidget);
  });

  testWidgets('opens Pencairan when that choice is selected', (tester) async {
    await pumpChooser(tester);

    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Pencairan'), findsOneWidget);
  });
}
