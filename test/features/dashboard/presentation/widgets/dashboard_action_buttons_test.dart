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

  testWidgets('choosing Setoran opens the setoran panel', (tester) async {
    await pumpActions(tester);
    await tester.tap(find.text('Catat Setoran'));
    await tester.pumpAndSettle();

    // The form itself is the evidence: on a wide window it arrives as a
    // panel over the dashboard rather than as the stub route behind it.
    expect(find.text('PILIH NASABAH'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('on a phone choosing Setoran opens the setoran page',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpActions(tester, isWeb: false);
    await tester.tap(find.text('Catat Setoran'));
    await tester.pumpAndSettle();

    expect(find.text('Form Setoran'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('offers Pencairan and opens its draft list', (tester) async {
    await pumpActions(tester);

    expect(find.text('Catat Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Pencairan'), findsOneWidget);
  });

  testWidgets('no open transaction refuses to draw the button at all',
      (tester) async {
    // The chooser requires at least one enabled choice; an empty set is a
    // programmer error, not a disabled button users can reach.
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
