import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_form_view.dart';
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

  /// The API a complete setoran needs: one nasabah, one jenis, and a save that
  /// succeeds.
  void stubSetoranApi() {
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        {
          'id': 'j1',
          'kode': 'K-j1',
          'nama_sampah': 'Botol PET',
          'kategori': 'plastik',
          'deskripsi': '',
          'harga_per_kg': '2000',
          'is_active': true,
        },
      ],
    });
    api.on('GET', '/api/v1/nasabah',
        json: nasabahPage([nasabahRow('n1', nama: 'Budi Santoso')]));
    api.on('POST', '/api/v1/transaksi', json: {
      'id': 't1',
      'total_nilai': '2000',
      'saldo_setelah_transaksi': '30000',
      'items': [{}],
    });
  }

  /// Opens the panel from [openHost]'s page and fills in one nasabah and one
  /// item, skipping the first-time tutorial.
  Future<void> fillSetoran(WidgetTester tester) async {
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();
    if (find.text('Lewati').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Tap untuk pilih nasabah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Item Setoran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Jenis').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Botol PET').last);
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

  /// The panel injects two different ways of leaving into the same form, and
  /// until now both were built by every test and run by none: constructed,
  /// so the lines looked covered to a reader, but never invoked.
  ///
  /// They are not interchangeable. The header's close button is an exit a
  /// Pengurus can hit by accident, so it goes through `maybePop` and the
  /// discard guard gets to ask. The form's own exit after a successful save
  /// is deliberate, so it spends the guard's one-shot key first and pops
  /// directly. Each needs its own case or the distinction is untested.
  testWidgets('the header close button closes the panel, not the page behind',
      (tester) async {
    await openHost(tester, const Size(1440, 900));
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('PILIH NASABAH'), findsOneWidget);
    // The first-time tutorial covers the panel until it is skipped.
    if (find.text('Lewati').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    }

    await tester.tap(
      find.descendant(
        of: find.byType(AppPanelHeader),
        matching: find.byTooltip('Tutup'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PILIH NASABAH'), findsNothing,
        reason: 'the panel is gone');
    expect(find.text('Tambah Transaksi'), findsOneWidget,
        reason: 'the page it was opened from is still there');
  });

  testWidgets('the panel can start the setoran tutorial again from its header',
      (tester) async {
    await openHost(tester, const Size(1440, 900));
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();
    if (find.text('Lewati').evaluate().isNotEmpty) {
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Lewati'), findsNothing);

    await tester.tap(find.descendant(
      of: find.byType(AppPanelHeader),
      matching: find.byTooltip('Panduan setoran'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Lewati'), findsOneWidget);
  });

  /// Esc and the scrim are one keystroke from the form, and a save in flight
  /// cannot be called back. Letting the panel go then drops the success panel
  /// and the WhatsApp draft of a setoran the server did record.
  testWidgets('a save in flight keeps the panel open, then shows its result',
      (tester) async {
    stubSetoranApi();
    await openHost(tester, const Size(1440, 900));
    await fillSetoran(tester);

    api.latency = const Duration(seconds: 1);
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Buang isi formulir?'), findsNothing,
        reason: 'nothing to decide while the request is out');
    expect(find.text('Simpan Transaksi'), findsNothing);
    expect(find.text('Menyimpan...'), findsOneWidget,
        reason: 'the panel is still there, still saving');

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Kirim Notif WhatsApp & Selesai'), findsOneWidget,
        reason: 'the result still reaches the person who saved it');
    await settleToasts(tester);
  });

  /// The setoran is recorded the moment the save resolves. From then on the
  /// form holds nothing that is unsaved, even though its fields are still
  /// filled in behind the success panel. Browser back during that window must
  /// not ask whether to throw away a transaction that already stands.
  testWidgets('a saved setoran no longer counts as unsaved input',
      (tester) async {
    stubSetoranApi();
    await openHost(tester, const Size(1440, 900));
    await fillSetoran(tester);
    final form = tester.state<SetoranFormViewState>(
      find.byType(SetoranFormView),
    );
    expect(form.hasUnsavedInput, isTrue, reason: 'filled in, not yet saved');

    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Kirim Notif WhatsApp & Selesai'), findsOneWidget,
        reason: 'the success panel is up');
    expect(form.hasUnsavedInput, isFalse,
        reason: 'the transaction is recorded; there is nothing left to lose');
    await tester.tap(find.text('Kirim Notif WhatsApp & Selesai'));
    await settleToasts(tester);
  });

  testWidgets('a tutorial step is no wider than the panel it points inside',
      (tester) async {
    await openHost(tester, const Size(1440, 900));
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih nasabah'), findsOneWidget,
        reason: 'the first-time tutorial opens with the panel');

    final panel = tester.getRect(find.byType(AppPanelHeader));
    final description = tester.getRect(find.textContaining('Ketuk kolom ini'));

    // The test font is far wider than the real one, so this only asks that the
    // text sit inside the panel, not how much room it leaves.
    expect(description.width, lessThan(panel.width),
        reason: 'a step wider than the panel pokes out over the page behind');
    expect(description.right, lessThan(panel.right));
    expect(description.left, greaterThan(panel.left));
  });

  testWidgets('the form closing itself closes the panel, not the page beneath',
      (tester) async {
    await openHost(tester, const Size(1440, 900));
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    // The post-save exit. Calling the injected strategy directly rather than
    // driving a whole save keeps this a test of the wiring, which is the part
    // the container owns: the form is handed a way out and does not choose it.
    tester.widget<SetoranFormView>(find.byType(SetoranFormView)).onClose();
    await tester.pumpAndSettle();

    expect(find.text('PILIH NASABAH'), findsNothing,
        reason: 'the panel closed');
    expect(find.text('Tambah Transaksi'), findsOneWidget,
        reason: 'GoRouter.pop() here would have popped the page beneath '
            'instead, because the panel is pushed on the navigator');
  });

  /// Raised on review of #186: the panel title sat 16px left of everything
  /// under it, so the panel read as two columns that did not quite agree.
  ///
  /// AppPanelHeader carries no padding of its own - every other caller that
  /// needs it to line up with inset content wraps it, as pengumuman_form_page
  /// does. The side sheet did not, while the form body adds AppSpacing.lg on
  /// top of the shared ContentInset. Asserting the two left edges are equal
  /// pins the relationship rather than the number, so it survives a change to
  /// either inset.
  testWidgets('the panel title lines up with the form content under it',
      (tester) async {
    await openHost(tester, const Size(1440, 900));
    await tester.tap(find.text('Tambah Transaksi'));
    await tester.pumpAndSettle();

    final title = tester.getTopLeft(
      find.descendant(
        of: find.byType(AppPanelHeader),
        matching: find.text('Transaksi Baru'),
      ),
    );
    final label = tester.getTopLeft(find.text('PILIH NASABAH'));

    expect(title.dx, label.dx,
        reason: 'the header title and the first section label are the '
            'left edge of the same column');
  });
}
