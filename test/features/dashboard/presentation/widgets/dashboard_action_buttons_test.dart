import 'package:flutter/material.dart';
import '../../../../support/setoran_form_support.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/transaksi_chooser_sheet.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import '../../../../support/analytics_scope.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_side_sheet.dart';

void main() {
  testWidgets('two main buttons, side by side, and no Pengumuman entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(withAnalytics(MaterialApp(
      home: Scaffold(body: DashboardActionButtons()),
    )));

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
    await tester
        .pumpWidget(withAnalytics(MaterialApp.router(routerConfig: router)));

    await tester.tap(find.textContaining('Tambah'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Nasabah'), findsOneWidget);
    expect(find.textContaining('Tambah'), findsOneWidget);
  });

  Future<GoRouter> pumpActions(
    WidgetTester tester, {
    Set<TransaksiPilihan> terbuka = transaksiPilihanTerbuka,
    bool isWeb = true,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          // On the web, because that is the only platform where recording a
          // setoran opens a panel rather than the form's own page. `kIsWeb`
          // is a compile-time constant and false under the VM, so a test
          // that means "web" has to say so.
          builder: (_, __) => Scaffold(
            body: DashboardActionButtons(isWeb: isWeb, terbuka: terbuka),
          ),
        ),
        GoRoute(
          path: TransaksiBaruPage.route,
          builder: (_, __) => const Scaffold(body: Text('Form Setoran')),
        ),
        GoRoute(
          path: DraftListPage.route,
          builder: (_, __) => const Scaffold(body: Text('Daftar Pencairan')),
        ),
        setoranSideSheetRoute(),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(withAnalytics(withSetoranFormProviders(
      child: MaterialApp.router(routerConfig: router),
    )));
    await tester.tap(find.text('Transaksi Baru'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('Transaksi Baru opens the setoran panel with no chooser',
      (tester) async {
    await pumpActions(tester);

    // The form itself is the evidence: on a wide window it arrives as a
    // panel over the dashboard rather than as the stub route behind it.
    expect(find.text('PILIH NASABAH'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Catat Setoran'), findsNothing,
        reason: 'one open transaction is not a choice worth a tap');
  });

  testWidgets('on a phone Transaksi Baru opens the setoran page',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpActions(tester, isWeb: false);

    expect(find.text('Form Setoran'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('offers no Pencairan, before or after the tap', (tester) async {
    await pumpActions(tester);

    expect(find.text('Pencairan'), findsNothing);
    expect(find.text('Daftar Pencairan'), findsNothing);
    expect(find.byIcon(Icons.payments_outlined), findsNothing);
  });

  testWidgets('reopening Pencairan is one edit: the chooser returns with it',
      (tester) async {
    // Proves the chooser and its wiring are still compiled and working, so
    // closing Pencairan stays one edit to transaksiPilihanTerbuka (plus its
    // route lock) rather than code to write again.
    await pumpActions(tester, terbuka: TransaksiPilihan.values.toSet());

    expect(find.text('Catat Setoran'), findsOneWidget);
    final pencairan = find
        .ancestor(of: find.text('Pencairan'), matching: find.byType(InkWell))
        .first;
    expect(tester.widget<InkWell>(pencairan).onTap, isNotNull);

    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Pencairan'), findsOneWidget);
  });

  testWidgets('no open transaction refuses to draw the button at all',
      (tester) async {
    // Closing the last transaction has to take the button with it: it would
    // open a chooser whose every row is inert, the dead control CPBI-31
    // forbids. Unreachable with the shipped constant, so the assert is the
    // statement of that, and this test is what keeps it honest.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: DashboardActionButtons(terbuka: {})),
    ));

    expect(tester.takeException(), isA<AssertionError>());
    expect(find.byType(TransaksiChooserSheet), findsNothing);
  });

  testWidgets('the chooser draws a closed choice inert', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TransaksiChooserSheet(tersedia: {TransaksiPilihan.setoran}),
      ),
    ));

    expect(find.text('Catat Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    final pencairan = find
        .ancestor(of: find.text('Pencairan'), matching: find.byType(InkWell))
        .first;
    expect(tester.widget<InkWell>(pencairan).onTap, isNull);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget,
        reason: 'only a choice that can be taken points anywhere');
  });
}
