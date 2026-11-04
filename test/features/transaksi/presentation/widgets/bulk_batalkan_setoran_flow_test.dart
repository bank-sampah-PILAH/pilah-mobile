import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/recent_activity_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/bulk_batalkan_setoran_dialog.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/fake_analytics_client.dart';
import '../../../../support/nasabah_support.dart';
import '../../../../support/pencairan_support.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _Get extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

ActivitasEntity _setoran(String id, {bool voided = false}) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'BU',
      avatarColor: AppColors.greenLight,
      textColor: AppColors.greenDark,
      name: id == 's1' ? 'Budi Santoso' : 'Sari Wijaya',
      subtitle: 'PET 2 kg',
      amount: '+Rp 6.000',
      isWaSuccess: false,
      time: '10:00',
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 11, 3, 10),
      isDibatalkan: voided,
    ));

class _Feed extends RiwayatAktivitasNotifier {
  _Feed() : super(_Get(), _Export());
  final voided = <String>{};
  bool failRefresh = false;
  Future<void> Function()? onLoad;
  int loads = 0;
  @override
  RiwayatAktivitasState build() => RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('s1'), _setoran('s2')],
        totalCount: 2,
      );
  @override
  Future<void> load({bool silent = false, int? pageSize}) async {
    loads++;
    await onLoad?.call();
    state = state.copyWith(
      status: failRefresh ? AktivitasStatus.failure : AktivitasStatus.loaded,
      items: [
        for (final id in ['s1', 's2']) _setoran(id, voided: voided.contains(id))
      ],
    );
  }
}

void main() {
  late StubApi api;
  late _Feed feed;
  late ProviderContainer container;
  late FakeAnalyticsClient analytics;

  Future<void> pumpPage(WidgetTester tester,
      {double width = 390, double textScale = 1, bool isWeb = true}) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api = StubApi();
    feed = _Feed();
    analytics = FakeAnalyticsClient();
    final transaksi = buildTransaksiNotifier(api);
    await tester.pumpWidget(withTransaksiProviders(
      transaksi: transaksi,
      riwayat: feed,
      nasabah: buildNasabahNotifier(api),
      analytics: analytics,
      child: ProviderScope(
        overrides: [
          dashboardProvider.overrideWith(() => buildDashboardNotifier(api)),
          recentActivityProvider.overrideWith(() => RecentActivityNotifier(
              transaksi.getTransaksiUseCase, buildPencairanUseCases(api))),
        ],
        child: MaterialApp(
            builder: (context, child) {
              container = ProviderScope.containerOf(context);
              return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!);
            },
            home: LaporanPage(isWeb: isWeb)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  void succeed(String id) =>
      api.onRequest('POST', '/api/v1/transaksi/$id/batalkan', json: (_) {
        feed.voided.add(id);
        return {
          'status': 'dibatalkan',
          'nasabah_nama': id == 's1' ? 'Budi Santoso' : 'Sari Wijaya',
          'total_nilai': '6000',
          'saldo_setelah_transaksi': '0',
          'items': [],
          'alasan_batal': 'Salah pencatatan',
          'dibatalkan_oleh_nama': 'Demo Pengurus'
        };
      });

  /// Same state the long-press and tap (phone) or the checkboxes (wide) leave.
  Future<void> select(WidgetTester tester, {bool both = true}) async {
    final selection = container.read(aktivitasSelectionProvider.notifier);
    selection.select('s1');
    if (both) selection.toggle('s2');
    await tester.pumpAndSettle();
  }

  Finder submit() => find.byWidgetPredicate(
      (w) => w is AppButton && w.label == 'Ya, hapus 2 setoran');
  Future<void> openDialog(WidgetTester tester) async {
    await select(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Hapus (2)'));
    await tester.pumpAndSettle();
  }

  Future<void> fillReason(WidgetTester tester) => tester.enterText(
        find.byKey(const ValueKey('bulk-void-alasan')),
        '  Salah pencatatan  ',
      );

  testWidgets(
      'confirmation names count and requires a nonblank reason before calls',
      (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    expect(find.text('Hapus 2 setoran?'), findsOneWidget);
    expect(api.requests, isEmpty);
    await tester.enterText(
        find.byKey(const ValueKey('bulk-void-alasan')), '   ');
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('Alasan pembatalan wajib diisi'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('cancel keeps both choices without issuing void calls',
      (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(container.read(aktivitasSelectionProvider), {'s1', 's2'});
    expect(api.requests, isEmpty);
  });

  for (final (width, isWeb) in [
    (390.0, true),
    (390.0, false),
    (1440.0, true)
  ]) {
    testWidgets(
        'bulk reuses PIL-428 endpoints and refreshes at $width, web=$isWeb',
        (tester) async {
      await pumpPage(tester, width: width, isWeb: isWeb);
      succeed('s1');
      succeed('s2');
      await openDialog(tester);
      await fillReason(tester);
      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(api.requests.map((r) => r.path),
          ['/api/v1/transaksi/s1/batalkan', '/api/v1/transaksi/s2/batalkan']);
      expect(api.requests.every((r) => r.json['alasan'] == 'Salah pencatatan'),
          isTrue);
      expect(find.text('2 setoran berhasil dibatalkan.'), findsOneWidget);
      expect(container.read(aktivitasSelectionProvider), isNull);
      expect(feed.loads, 2);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Dibatalkan'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'partial failure identifies the failed setoran and keeps only that choice',
      (tester) async {
    await pumpPage(tester);
    succeed('s1');
    const error =
        'Setoran ini tidak bisa dibatalkan karena sebagian saldonya sudah dicairkan';
    api.on('POST', '/api/v1/transaksi/s2/batalkan',
        status: 409, json: {'error': error});
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('1 setoran berhasil dibatalkan.'), findsOneWidget);
    expect(find.text(error), findsOneWidget);
    expect(find.textContaining('Sari Wijaya'), findsWidgets);
    expect(container.read(aktivitasSelectionProvider), {'s2'});
    expect(api.requests, hasLength(2));
  });

  testWidgets('a bulk void reports how many setoran were really voided',
      (tester) async {
    await pumpPage(tester);
    succeed('s1');
    const error = 'Tidak bisa dibatalkan';
    api.on('POST', '/api/v1/transaksi/s2/batalkan',
        status: 409, json: {'error': error});
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();

    expect(analytics.events.single.name, 'riwayat_setoran_dibatalkan');
    expect(analytics.events.single.properties,
        {'cara': 'massal', 'jumlah_setoran': 1});
  });

  testWidgets('a bulk void that voided nothing reports nothing',
      (tester) async {
    await pumpPage(tester);
    api.on('POST', '/api/v1/transaksi/s1/batalkan',
        status: 409, json: {'error': 'Tidak bisa dibatalkan'});
    api.on('POST', '/api/v1/transaksi/s2/batalkan',
        status: 409, json: {'error': 'Tidak bisa dibatalkan'});
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();

    expect(analytics.events, isEmpty);
  });

  testWidgets(
      'timeout reports uncertain status and does not send the next void',
      (tester) async {
    await pumpPage(tester);
    api.fail('POST', '/api/v1/transaksi/s1/batalkan');
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(1));
    expect(find.text('Status belum dipastikan'), findsOneWidget);
    expect(find.text('Belum diproses'), findsOneWidget);
    expect(find.text('0 setoran berhasil dibatalkan.'), findsOneWidget);
  });

  testWidgets('expired session stops remaining requests', (tester) async {
    await pumpPage(tester);
    api.on('POST', '/api/v1/transaksi/s1/batalkan',
        status: 401, json: {'error': 'Sesi berakhir'});
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(1));
    expect(find.text('Sesi berakhir'), findsOneWidget);
    expect(find.text('Belum diproses'), findsOneWidget);
  });

  testWidgets('rate limit stops the batch and retains untouched choices',
      (tester) async {
    await pumpPage(tester);
    api.on('POST', '/api/v1/transaksi/s1/batalkan',
        status: 429, json: {'error': 'Terlalu banyak permintaan'});
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(1));
    expect(find.text('Terlalu banyak permintaan'), findsOneWidget);
    expect(find.text('Belum diproses'), findsOneWidget);
    expect(find.textContaining('Batas permintaan tercapai'), findsOneWidget);
    expect(container.read(aktivitasSelectionProvider), {'s1', 's2'});
  });

  testWidgets('processing locks submission, cancellation and back navigation',
      (tester) async {
    await pumpPage(tester);
    succeed('s1');
    succeed('s2');
    api.latency = const Duration(milliseconds: 500);
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pump();
    expect(tester.widget<AppButton>(submit()).isLoading, isTrue);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Kembali'))
            .onPressed,
        isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Hapus 2 setoran?'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(2));
  });

  testWidgets('refresh failure preserves confirmed void outcomes',
      (tester) async {
    await pumpPage(tester);
    succeed('s1');
    succeed('s2');
    await openDialog(tester);
    await fillReason(tester);
    feed.failRefresh = true;
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('2 setoran berhasil dibatalkan.'), findsOneWidget);
    expect(find.textContaining('riwayat belum berhasil dimuat ulang'),
        findsOneWidget);
    expect(api.requests, hasLength(2));
  });

  testWidgets('stale selection is cleared without opening a confirmation',
      (tester) async {
    await pumpPage(tester);
    final selection = container.read(aktivitasSelectionProvider.notifier);
    selection.select('no-longer-in-history');
    await showBulkBatalkanSetoranDialog(
        tester.element(find.byType(LaporanPage)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(container.read(aktivitasSelectionProvider), isNull);
    expect(find.byType(BulkBatalkanSetoranDialog), findsNothing);
    expect(find.text('Pilihan tidak tersedia'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Pilihan sudah tidak tersedia di riwayat terbaru'),
        findsOneWidget);
    expect(api.requests, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('session change during a void dismisses stale results and stops',
      (tester) async {
    await pumpPage(tester);
    api.onRequest('POST', '/api/v1/transaksi/s1/batalkan', json: (_) {
      api.utils.setToken(accessToken: 'new-demo-session', refreshToken: 'demo');
      return {'status': 'dibatalkan', 'items': []};
    });
    await openDialog(tester);
    await fillReason(tester);
    final loads = feed.loads;
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(1));
    expect(feed.loads, loads, reason: 'old session must not refresh caches');
    expect(container.read(aktivitasSelectionProvider), isNull);
    expect(find.byType(BulkBatalkanSetoranDialog), findsNothing);
    expect(find.text('Hasil pembatalan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('session change during refresh dismisses old session results',
      (tester) async {
    await pumpPage(tester);
    succeed('s1');
    succeed('s2');
    await openDialog(tester);
    await fillReason(tester);
    feed.onLoad = () async {
      api.utils.setToken(accessToken: 'new-demo-session', refreshToken: 'demo');
    };
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(2));
    expect(feed.loads, 2);
    expect(container.read(aktivitasSelectionProvider), isNull);
    expect(find.byType(BulkBatalkanSetoranDialog), findsNothing);
    expect(find.text('Hasil pembatalan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh exception preserves successful outcomes and warns',
      (tester) async {
    await pumpPage(tester);
    succeed('s1');
    succeed('s2');
    await openDialog(tester);
    await fillReason(tester);
    feed.onLoad = () async => throw StateError('Demo refresh interrupted');
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('2 setoran berhasil dibatalkan.'), findsOneWidget);
    expect(find.textContaining('riwayat belum berhasil dimuat ulang'),
        findsOneWidget);
    expect(container.read(aktivitasSelectionProvider), isNull);
    expect(api.requests, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('void reloads already initialized dashboard and customer caches',
      (tester) async {
    await pumpPage(tester);
    // Mirrors a user who visited Dashboard and Nasabah before Riwayat.
    container.read(dashboardProvider);
    container.read(recentActivityProvider);
    container.read(nasabahProvider);
    api.on('GET', '/api/v1/dashboard/stats', json: {
      'total_nilai_bulan_ini': 0,
      'nasabah_aktif': 1,
      'total_sampah_kg_bulan_ini': 0,
      'transaksi_bulan_ini': 0,
    });
    api.on('GET', '/api/v1/transaksi', json: {'results': []});
    api.on('GET', '/api/v1/pencairan', json: {'results': [], 'next': null});
    api.on('GET', '/api/v1/nasabah',
        json: nasabahPage([nasabahRow('n1', saldo: '0')]));
    succeed('s1');
    succeed('s2');
    await openDialog(tester);
    await fillReason(tester);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('2 setoran berhasil dibatalkan.'), findsOneWidget);
    final dashboard = container.read(dashboardProvider);
    expect(dashboard.isLoaded, isTrue);
    expect(dashboard.totalKasBulanIni, 0);
    expect(dashboard.totalNasabahAktif, 1);
    expect(container.read(recentActivityProvider), isA<RecentActivityLoaded>());
    final customers = container.read(nasabahProvider) as NasabahLoaded;
    expect(customers.nasabahList.single.balance, 'Rp 0');
    expect(api.requests.where((r) => r.method == 'POST'), hasLength(2));
    expect(
        api.requests.where((r) => r.method == 'GET').map((r) => r.path),
        containsAll([
          '/api/v1/dashboard/stats',
          '/api/v1/transaksi',
          '/api/v1/pencairan',
          '/api/v1/nasabah',
        ]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation and full failure reason fit 320px with large text',
      (tester) async {
    await pumpPage(tester, width: 320, textScale: 2);
    api.on('POST', '/api/v1/transaksi/s1/batalkan',
        status: 409, json: {'error': 'Setoran sudah dibatalkan'});
    api.on('POST', '/api/v1/transaksi/s2/batalkan',
        status: 409, json: {'error': 'Saldo tidak mencukupi'});
    await openDialog(tester);
    await fillReason(tester);
    await tester.ensureVisible(submit());
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('0 setoran berhasil dibatalkan.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
