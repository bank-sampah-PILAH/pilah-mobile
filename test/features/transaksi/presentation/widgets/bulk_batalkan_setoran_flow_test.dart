import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';

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

  Future<void> pumpPage(WidgetTester tester,
      {double width = 390, double textScale = 1}) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api = StubApi();
    feed = _Feed();
    await tester.pumpWidget(withTransaksiProviders(
      transaksi: buildTransaksiNotifier(api),
      riwayat: feed,
      child: MaterialApp(
          builder: (context, child) {
            container = ProviderScope.containerOf(context);
            return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!);
          },
          home: const LaporanPage(isWeb: true)),
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

  Future<void> select(WidgetTester tester, {bool both = true}) async {
    await tester.tap(find.text('Opsi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Setoran'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    if (both) {
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
    }
  }

  Finder submit() => find.widgetWithText(AppButton, 'Ya, hapus 2 setoran');
  Future<void> openDialog(WidgetTester tester) async {
    await select(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Hapus (2)'));
    await tester.pumpAndSettle();
  }

  Future<void> fillReason(WidgetTester tester) => tester.enterText(
        find.byKey(const ValueKey('bulk-void-alasan')),
        '  Salah pencatatan  ',
      );

  testWidgets('empty selection disables bulk Hapus', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Opsi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Setoran'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Hapus (0)'))
            .onPressed,
        isNull);
    expect(api.requests, isEmpty);
  });

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
    expect(container.read(aktivitasBulkSelectionProvider), {'s1', 's2'});
    expect(api.requests, isEmpty);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets(
        'bulk reuses both PIL-428 endpoints and refreshes statuses at $width',
        (tester) async {
      await pumpPage(tester, width: width);
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
      expect(container.read(aktivitasBulkSelectionProvider), isNull);
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
    expect(container.read(aktivitasBulkSelectionProvider), {'s2'});
    expect(api.requests, hasLength(2));
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
