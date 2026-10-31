import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _TestRiwayatNotifier extends RiwayatAktivitasNotifier {
  _TestRiwayatNotifier(this.initialState)
      : super(_MockGetAktivitas(), _MockExportTransaksi());

  final RiwayatAktivitasState initialState;
  final calls = <String>[];

  @override
  RiwayatAktivitasState build() => initialState;

  @override
  Future<void> load({bool silent = false, int? pageSize}) async =>
      calls.add('load:$silent');

  @override
  Future<void> loadMore() async => calls.add('loadMore');

  @override
  Future<void> loadPage(int page) async => calls.add('loadPage:$page');
}

class _MockGetAktivitas extends Mock implements GetAktivitasUseCase {}

class _MockExportTransaksi extends Mock implements ExportTransaksiUseCase {}

final _now = DateTime(2026, 10, 5, 12);

ActivitasEntity _setoran(String name, DateTime? at, {String id = 't1'}) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'AB',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: name,
      subtitle: '2 jenis sampah',
      amount: '+Rp 5.000',
      isWaSuccess: true,
      time: '10:00',
      balance: 'Rp 5.000',
      items: [
        ItemSetoranEntity(
            jenis: 'Plastik',
            berat: '2 kg',
            harga: 'Rp 1.000',
            subtotal: 'Rp 2.000'),
      ],
      tanggal: at,
    ));

ActivitasEntity _pencairan(String name, DateTime at) =>
    ActivitasEntity.fromPencairan(Pencairan(
      id: 'p-1',
      nasabahId: 'n-1',
      nasabahNama: name,
      nominal: 15000,
      metode: MetodePencairan.tunai,
      tanggal: at,
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 20000,
      saldoSesudah: 5000,
      dicatatOlehNama: 'Ibu Sari',
    ));

Map<String, dynamic> _detailPayload(String name) => {
      'nasabah_nama': name,
      'total_nilai': '5000',
      'saldo_setelah_transaksi': '10000',
      'status_wa': 'terkirim',
      'items': [
        {
          'nama_sampah_snapshot': 'Plastik',
          'berat': '2',
          'harga_snapshot': '1000',
          'subtotal': '2000',
        },
      ],
      'catatan': 'Setoran diperiksa',
      'revisi': [
        {
          'versi': 1,
          'total_nilai': '4000',
          'catatan': '',
          'alasan': 'Salah timbang',
          'diubah_oleh_nama': 'Ibu Sari',
          'items': [],
        },
      ],
    };

void main() {
  late _TestRiwayatNotifier feedNotifier;
  late TransaksiNotifier transaksi;
  late StubApi api;

  setUp(() {
    api = StubApi();
    transaksi = buildTransaksiNotifier(api);
  });

  Future<void> pumpList(WidgetTester tester, RiwayatAktivitasState state,
      {bool isWeb = kIsWeb}) async {
    feedNotifier = _TestRiwayatNotifier(state);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => withTransaksiProviders(
          riwayat: feedNotifier,
          transaksi: transaksi,
          child: Scaffold(
            body: AktivitasListView(now: () => _now, isWeb: isWeb),
          ),
        ),
      ),
      GoRoute(
        path: EditPencairanPage.route,
        builder: (context, _) => Scaffold(
          body: TextButton(
              onPressed: () => context.pop(true), child: const Text('simpan')),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  testWidgets('shows skeleton rows while the feed loads', (tester) async {
    await pumpList(tester, const RiwayatAktivitasState());
    expect(find.byType(SkeletonListItem), findsWidgets);

    await pumpList(
        tester, const RiwayatAktivitasState(status: AktivitasStatus.loading));
    expect(find.byType(SkeletonListItem), findsWidgets);
  });

  testWidgets('explains a failed load, with a fallback message',
      (tester) async {
    await pumpList(
        tester,
        const RiwayatAktivitasState(
            status: AktivitasStatus.failure, errorMessage: 'Koneksi putus'));
    expect(find.text('Gagal Memuat Data'), findsOneWidget);
    expect(find.text('Koneksi putus'), findsOneWidget);

    await pumpList(
        tester, const RiwayatAktivitasState(status: AktivitasStatus.failure));
    expect(find.text('Terjadi kesalahan'), findsOneWidget);
  });

  testWidgets('distinguishes an empty period from an empty search',
      (tester) async {
    await pumpList(
        tester, const RiwayatAktivitasState(status: AktivitasStatus.loaded));
    expect(find.text('Belum Ada Aktivitas'), findsOneWidget);

    await pumpList(
        tester,
        const RiwayatAktivitasState(
            status: AktivitasStatus.loaded, search: 'zzz'));
    expect(find.text('Aktivitas Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('groups rows under day headings', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
        tester,
        RiwayatAktivitasState(status: AktivitasStatus.loaded, items: [
          _setoran('Ani', _now),
          _setoran('Budi', DateTime(2026, 10, 4, 9)),
          _setoran('Citra', DateTime(2026, 10, 2, 9)),
          _setoran('Dewi', null),
        ]));

    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('KEMARIN'), findsOneWidget);
    expect(find.text('3 HARI LALU'), findsOneWidget);
    expect(find.text('LAINNYA'), findsOneWidget);
    expect(find.text('Ani'), findsOneWidget);
  });

  testWidgets('setoran details expand inline on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on('GET', '/api/v1/transaksi/t1', json: _detailPayload('Ani'));
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded, items: [_setoran('Ani', _now)]));

    expect(find.byType(AktivitasTable), findsOneWidget);
    expect(find.text('HARI INI'), findsNothing);
    expect(find.text('Plastik'), findsNothing);

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();

    expect(find.text('Plastik'), findsOneWidget);
    expect(find.text('Setoran diperiksa'), findsOneWidget);
    expect(find.text('Saldo setelah transaksi'), findsOneWidget);
    expect(find.text('Rp 10.000'), findsOneWidget);
    expect(find.text('RIWAYAT PERUBAHAN'), findsOneWidget);
    expect(find.text('Alasan: Salah timbang'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Total Setoran'), findsNothing);
    expect(find.text('+Rp 5.000'), findsOneWidget);
    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('05/10/2026'), findsOneWidget);

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik'), findsNothing);
  });

  testWidgets('setoran details expand inline on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on('GET', '/api/v1/transaksi/t1', json: _detailPayload('Ani'));
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded, items: [_setoran('Ani', _now)]));

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();

    expect(find.text('Plastik'), findsOneWidget);
    expect(find.text('Setoran diperiksa'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Total Setoran'), findsNothing);
    expect(find.text('+Rp 5.000'), findsOneWidget);
    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('05/10/2026'), findsOneWidget);
  });

  testWidgets('a failed inline detail can be retried', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on('GET', '/api/v1/transaksi/t1', status: 500, json: {});
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded, items: [_setoran('Ani', _now)]));

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian setoran tidak dapat dimuat.'), findsOneWidget);

    api.on('GET', '/api/v1/transaksi/t1', json: _detailPayload('Ani'));
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik'), findsOneWidget);
  });

  testWidgets('a setoran without an id expands without a request',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded,
            items: [_setoran('Ani', _now, id: '')]));

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();

    expect(find.text('Rincian setoran tidak tersedia.'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a saved pencairan edit refreshes the feed silently',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded, items: [_pencairan('Budi', _now)]));

    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('edit-pencairan')));
    await tester.tap(find.byKey(const Key('edit-pencairan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('simpan'));
    await tester.pumpAndSettle();

    expect(feedNotifier.calls, contains('load:true'));
  });
  testWidgets('initial failure retry requests the first page', (tester) async {
    await pumpList(
        tester,
        const RiwayatAktivitasState(
            status: AktivitasStatus.failure, errorMessage: 'offline'));
    await tester.tap(find.text('Coba Lagi'));
    expect(feedNotifier.calls, contains('load:false'));
  });

  testWidgets('loading the next page preserves existing rows', (tester) async {
    await pumpList(
        tester,
        RiwayatAktivitasState(
            status: AktivitasStatus.loaded,
            loadingMore: true,
            items: [_setoran('Siti', _now)]));
    expect(find.text('Siti'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  if (!kIsWeb) {
    for (final error in <String?>[null, 'Halaman berikutnya gagal']) {
      testWidgets('next-page action retains rows and retries: $error',
          (tester) async {
        await pumpList(
            tester,
            RiwayatAktivitasState(
                status: AktivitasStatus.loaded,
                hasNext: true,
                errorMessage: error,
                items: [_setoran('Siti', _now)]));
        expect(find.text('Siti'), findsOneWidget);
        if (error != null) expect(find.text(error), findsOneWidget);
        await tester.tap(find.text(error == null ? 'Muat Lagi' : 'Coba Lagi'));
        expect(feedNotifier.calls, contains('loadMore'));
      });
    }
  }

  testWidgets('web retry uses the failed server page', (tester) async {
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        hasNext: true,
        errorMessage: 'Halaman gagal dimuat',
        retryPage: 2,
        items: [_setoran('Siti', _now)],
      ),
      isWeb: true,
    );

    expect(find.text('Coba Lagi'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    expect(feedNotifier.calls, contains('loadPage:2'));
  });
}
