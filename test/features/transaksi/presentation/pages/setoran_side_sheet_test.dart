import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_side_sheet.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/harga_support.dart';
import '../../../../support/nasabah_support.dart';
import '../../../../support/pencairan_support.dart';
import '../../../../support/profile_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

/// Recording a setoran should not cost the Pengurus the page they were working
/// from. `/transaksi-baru` is a top-level route outside the shell, so pushing
/// it covers the navigation rail and the list underneath; on a wide window the
/// same form belongs in a panel with the page still behind it.
///
/// The phone keeps the page. There is no room to leave anything visible at that
/// width, and the route already exists and already works — so the narrow path
/// is asserted here too, to pin that this change does not reach it.
void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    api.on('GET', '/api/v1/jenis-sampah', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/nasabah', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/pengaturan/wa-template', json: <String, dynamic>{});
    api.on('GET', '/api/v1/transaksi', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/aktivitas', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/pencairan', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/dashboard/stats', json: <String, dynamic>{});
  });

  /// A stand-in for the page a Pengurus opens the form from, with one button
  /// that asks for the form the way this window should show it.
  Future<void> openHost(
    WidgetTester tester,
    Size window, {
    bool isWeb = true,
  }) async {
    final harga = buildHargaNotifier(api);
    final profile = buildProfileNotifier(api);
    final transaksi = buildTransaksiNotifier(api);
    final dashboard = buildDashboardNotifier(api);
    final pencairan = buildPencairanUseCases(api);
    final recent = RecentActivityNotifier(
      GetTransaksiUseCase(
        TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network)),
      ),
      pencairan,
    );
    final riwayat = buildRiwayatAktivitasNotifier(api);
    final nasabah = buildNasabahNotifier(api);

    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              // Web by default, including for the narrow case: the phone
              // this file pins is a *browser* at phone width. `kIsWeb` is a
              // compile-time constant and false under the VM, so a test that
              // means web has to say so.
              onPressed: () => openSetoranBaru(context, isWeb: isWeb),
              child: const Text('Tambah Transaksi'),
            ),
          ),
        ),
      ),
      // Rendered as plain `route:/transaksi-baru` text, so navigating to the
      // page is observable without building the real one.
      extraRoutes: [TransaksiBaruPage.route],
      // The app's own panel route, so the test drives the declared route
      // rather than a stand-in that could drift from it.
      realRoutes: [setoranSideSheetRoute()],
      wrap: (app) => ProviderScope(
        overrides: [
          dashboardProvider.overrideWith(() => dashboard),
          recentActivityProvider.overrideWith(() => recent),
          profileProvider.overrideWith(() => profile),
        ],
        child: withTransaksiProviders(
          child: app,
          harga: harga,
          transaksi: transaksi,
          riwayat: riwayat,
          nasabah: nasabah,
        ),
      ),
      size: window,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a wide window gets the form in a panel over the page',
      (tester) async {
    await openHost(tester, const Size(1440, 900));

    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('PILIH NASABAH'), findsOneWidget,
        reason: 'the form itself is on screen');
    expect(find.text('route:${TransaksiBaruPage.route}'), findsNothing,
        reason: 'it is a panel, not a navigation');
    expect(find.text('Tambah Transaksi'), findsOneWidget,
        reason: 'the page it was opened from is still there behind the panel');
  });

  testWidgets('the panel does not cover the whole window', (tester) async {
    await openHost(tester, const Size(1440, 900));
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    final panel = tester.getRect(find.text('PILIH NASABAH'));
    expect(panel.left, greaterThan(600),
        reason: 'the form sits in the right-hand panel, not across the page');
  });

  testWidgets('a phone-width window still gets the form as its own page',
      (tester) async {
    await openHost(tester, const Size(390, 844));

    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('route:${TransaksiBaruPage.route}'), findsOneWidget,
        reason: 'the existing full-screen route is untouched on a phone');
  });

  /// The case the width rule alone got wrong. A native tablet is 768 or wider
  /// and is not `compact`, so a resolver that only looked at width handed it a
  /// panel — but PIL-432 is a web ticket and the app has no browser shell to
  /// leave visible behind one. Raised on review of PR #186; this is the same
  /// guarantee at the level a Pengurus would actually meet it.
  testWidgets('a native tablet keeps the form as its own page', (tester) async {
    await openHost(tester, const Size(1440, 900), isWeb: false);

    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('route:${TransaksiBaruPage.route}'), findsOneWidget,
        reason: 'width said panel; the platform says page, and wins');
    expect(find.text('PILIH NASABAH'), findsNothing,
        reason: 'no panel is mounted on the native app at any width');
  });
}
