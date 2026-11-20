import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_setoran_detail.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_table.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/batalkan_setoran_dialog.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/edit_setoran_sheet.dart';

import '../../../../support/fake_analytics_client.dart';
import '../../../../support/harga_support.dart';
import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

class _TestRiwayatNotifier extends RiwayatAktivitasNotifier {
  _TestRiwayatNotifier(this.initialState)
      : super(_MockGetAktivitas(), _MockExportTransaksi());

  final RiwayatAktivitasState initialState;
  final calls = <String>[];

  void updateState(RiwayatAktivitasState value) => state = value;

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

ActivitasEntity _setoran(String name, DateTime? at, {String id = ''}) =>
    ActivitasEntity.fromTransaksi(
      TransaksiEntity(
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
            subtotal: 'Rp 2.000',
          ),
        ],
        tanggal: at,
      ),
    );

ActivitasEntity _pencairan(String name, DateTime at) =>
    ActivitasEntity.fromPencairan(
      Pencairan(
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
      ),
    );

void main() {
  late _TestRiwayatNotifier feedNotifier;
  late TransaksiNotifier transaksi;
  late StubApi api;
  late FakeAnalyticsClient analytics;

  setUp(() {
    api = StubApi();
    analytics = FakeAnalyticsClient();
    transaksi = buildTransaksiNotifier(api);
  });

  Future<void> pumpList(
    WidgetTester tester,
    RiwayatAktivitasState state, {
    bool isWeb = kIsWeb,
  }) async {
    feedNotifier = _TestRiwayatNotifier(state);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => withTransaksiProviders(
            riwayat: feedNotifier,
            transaksi: transaksi,
            analytics: analytics,
            child: Scaffold(
              body: AktivitasListView(now: () => _now, isWeb: isWeb),
            ),
          ),
        ),
        GoRoute(
          path: EditPencairanPage.route,
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(true),
              child: const Text('simpan'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  testWidgets('shows skeleton rows while the feed loads', (tester) async {
    await pumpList(tester, const RiwayatAktivitasState());
    expect(find.byType(SkeletonListItem), findsWidgets);

    await pumpList(
      tester,
      const RiwayatAktivitasState(status: AktivitasStatus.loading),
    );
    expect(find.byType(SkeletonListItem), findsWidgets);
  });

  testWidgets('explains a failed load, with a fallback message', (
    tester,
  ) async {
    await pumpList(
      tester,
      const RiwayatAktivitasState(
        status: AktivitasStatus.failure,
        errorMessage: 'Koneksi putus',
      ),
    );
    expect(find.text('Gagal Memuat Data'), findsOneWidget);
    expect(find.text('Koneksi putus'), findsOneWidget);

    await pumpList(
      tester,
      const RiwayatAktivitasState(status: AktivitasStatus.failure),
    );
    expect(find.text('Terjadi kesalahan'), findsOneWidget);
  });

  testWidgets('distinguishes an empty period from an empty search', (
    tester,
  ) async {
    await pumpList(
      tester,
      const RiwayatAktivitasState(status: AktivitasStatus.loaded),
    );
    expect(find.text('Belum Ada Aktivitas'), findsOneWidget);

    await pumpList(
      tester,
      const RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        search: 'zzz',
      ),
    );
    expect(find.text('Aktivitas Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('groups rows under day headings', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [
          _setoran('Ani', _now),
          _setoran('Budi', DateTime(2026, 10, 4, 9)),
          _setoran('Citra', DateTime(2026, 10, 2, 9)),
          _setoran('Dewi', null),
        ],
      ),
    );

    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('KEMARIN'), findsOneWidget);
    expect(find.text('3 HARI LALU'), findsOneWidget);
    expect(find.text('LAINNYA'), findsOneWidget);
    expect(find.text('Ani'), findsOneWidget);
  });

  testWidgets('setoran details expand inline in the wide table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on(
      'GET',
      '/api/v1/transaksi/t1',
      json: {
        'nasabah_nama': 'Ani',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '42000',
        'items': [
          {
            'nama_sampah_snapshot': 'Botol Kaca',
            'berat': '1',
            'harga_snapshot': '5000',
            'subtotal': '5000',
          },
        ],
      },
    );
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('Ani', _now, id: 't1')],
      ),
    );

    expect(find.byType(AktivitasTable), findsOneWidget);
    expect(find.text('HARI INI'), findsNothing);
    expect(find.text('Botol Kaca'), findsNothing);

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();

    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('+Rp 5.000'), findsOneWidget);
    expect(find.text('Botol Kaca'), findsOneWidget);
    expect(find.text('Rp 42.000'), findsOneWidget);
    expect(find.text('Total Setoran'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Botol Kaca'), findsNothing);
  });

  group('what opening a detail reports', () {
    List<Map<String, Object>> opened() => [
          for (final e in analytics.events)
            if (e.name == 'riwayat_detail_dibuka') e.properties,
        ];

    testWidgets('expanding a setoran in the wide table says it was a setoran', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      api.on(
        'GET',
        '/api/v1/transaksi/t1',
        json: {
          'nasabah_nama': 'Ani',
          'total_nilai': '5000',
          'saldo_setelah_transaksi': '42000',
          'items': [],
        },
      );
      await pumpList(
        tester,
        RiwayatAktivitasState(
          status: AktivitasStatus.loaded,
          items: [_setoran('Ani', _now, id: 't1')],
        ),
      );

      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();
      expect(opened(), [
        {'jenis_aktivitas': 'setoran'},
      ]);

      // Closing it again is not opening a detail.
      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();
      expect(opened(), hasLength(1));
    });

    testWidgets('expanding a setoran on a phone says it was a setoran', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      api.on(
        'GET',
        '/api/v1/transaksi/t1',
        json: {
          'nasabah_nama': 'Ani',
          'total_nilai': '5000',
          'saldo_setelah_transaksi': '42000',
          'items': [],
        },
      );
      await pumpList(
        tester,
        RiwayatAktivitasState(
          status: AktivitasStatus.loaded,
          items: [_setoran('Ani', _now, id: 't1')],
        ),
      );

      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();
      expect(opened(), [
        {'jenis_aktivitas': 'setoran'},
      ]);

      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();
      expect(opened(), hasLength(1));
    });

    testWidgets('opening a pencairan says it was a pencairan', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpList(
        tester,
        RiwayatAktivitasState(
          status: AktivitasStatus.loaded,
          items: [_pencairan('Budi', _now)],
        ),
        isWeb: true,
      );

      await tester.tap(find.text('Budi'));
      await tester.pumpAndSettle();

      expect(opened(), [
        {'jenis_aktivitas': 'pencairan'},
      ]);
    });
  });

  testWidgets('a pencairan row still opens its detail in the wide table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_pencairan('Budi', _now)],
      ),
      isWeb: true,
    );

    await tester.tap(find.text('Budi'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pencairan'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsNWidgets(2));
  });

  testWidgets('a setoran expands inline without repeating row details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on(
      'GET',
      '/api/v1/transaksi/t1',
      json: {
        'nasabah_nama': 'Ani',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '42000',
        'catatan': 'Ditimbang ulang',
        'items': [
          {
            'nama_sampah_snapshot': 'Aluminium',
            'berat': '1.5',
            'harga_snapshot': '3000',
            'subtotal': '4500',
          },
        ],
        'revisi': [
          {
            'versi': 1,
            'total_nilai': '4000',
            'catatan': '',
            'alasan': 'Salah timbang',
            'diubah_oleh_nama': 'Ibu Sari',
            'items': [],
          },
          {
            'versi': 2,
            'total_nilai': '4500',
            'catatan': 'Catatan terdahulu',
            'alasan': 'Penyesuaian',
            'diubah_oleh_nama': 'Pak Budi',
            'diubah_pada': '2026-10-04T12:34:00Z',
            'items': [
              {
                'nama_sampah': 'Kardus',
                'berat': '1.25',
                'harga': '800',
                'subtotal': '1000',
              },
            ],
          },
        ],
      },
    );
    api.latency = const Duration(milliseconds: 300);
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('Ani', _now, id: 't1')],
      ),
    );

    await tester.tap(find.text('Ani'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Ani'), findsOneWidget);
    expect(find.text('+Rp 5.000'), findsOneWidget);
    expect(find.text('Aluminium'), findsOneWidget);
    expect(find.text('Rp 42.000'), findsOneWidget);
    expect(find.text('Ditimbang ulang'), findsOneWidget);
    expect(find.text('RIWAYAT PERUBAHAN'), findsOneWidget);
    expect(find.text('Alasan: Salah timbang'), findsOneWidget);
    expect(
      find.textContaining('Diubah oleh Pak Budi • 04/10/2026'),
      findsOneWidget,
    );
    expect(find.textContaining('Kardus •'), findsOneWidget);
    expect(find.text('Catatan: Catatan terdahulu'), findsOneWidget);
    expect(find.text('Total Setoran'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Aluminium'), findsNothing);
  });

  testWidgets('replacing an expanded feed item does not reuse its details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    api.on(
      'GET',
      '/api/v1/transaksi/t1',
      json: {
        'nasabah_nama': 'Ani',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '42000',
        'items': [
          {
            'nama_sampah_snapshot': 'Plastik',
            'berat': '1',
            'harga_snapshot': '5000',
            'subtotal': '5000',
          },
        ],
      },
    );
    api.on(
      'GET',
      '/api/v1/transaksi/t2',
      json: {
        'nasabah_nama': 'Citra',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '42000',
        'items': [
          {
            'nama_sampah_snapshot': 'Kardus',
            'berat': '1',
            'harga_snapshot': '5000',
            'subtotal': '5000',
          },
        ],
      },
    );
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('Ani', _now, id: 't1')],
      ),
    );

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Plastik'), findsOneWidget);

    feedNotifier.updateState(
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        search: 'Citra',
        items: [_setoran('Citra', _now, id: 't2')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Citra'), findsOneWidget);
    expect(find.text('Kardus'), findsNothing);
    expect(api.requests.map((request) => request.path), [
      '/api/v1/transaksi/t1',
    ]);
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
        status: AktivitasStatus.loaded,
        items: [_setoran('Ani', _now, id: 't1')],
      ),
    );

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian setoran tidak dapat dimuat.'), findsOneWidget);

    api.on(
      'GET',
      '/api/v1/transaksi/t1',
      json: {
        'nasabah_nama': 'Ani',
        'total_nilai': '5000',
        'saldo_setelah_transaksi': '42000',
        'items': [
          {
            'nama_sampah_snapshot': 'Botol Kaca',
            'berat': '1',
            'harga_snapshot': '5000',
            'subtotal': '5000',
          },
        ],
      },
    );
    expect(find.text('Coba Lagi'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Botol Kaca'), findsOneWidget);
    expect(api.requests, hasLength(2));
  });

  testWidgets('a setoran without an id shows unavailable details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_setoran('Ani', _now)],
      ),
    );

    await tester.tap(find.text('Ani'));
    await tester.pumpAndSettle();

    expect(find.text('Rincian setoran tidak tersedia.'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a saved pencairan edit refreshes the feed silently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        items: [_pencairan('Budi', _now)],
      ),
    );

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
        status: AktivitasStatus.failure,
        errorMessage: 'offline',
      ),
    );
    await tester.tap(find.text('Coba Lagi'));
    expect(feedNotifier.calls, contains('load:false'));
  });

  testWidgets('loading the next page preserves existing rows', (tester) async {
    await pumpList(
      tester,
      RiwayatAktivitasState(
        status: AktivitasStatus.loaded,
        loadingMore: true,
        items: [_setoran('Siti', _now)],
      ),
    );
    expect(find.text('Siti'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  if (!kIsWeb) {
    for (final error in <String?>[null, 'Halaman berikutnya gagal']) {
      testWidgets('next-page action retains rows and retries: $error', (
        tester,
      ) async {
        await pumpList(
          tester,
          RiwayatAktivitasState(
            status: AktivitasStatus.loaded,
            hasNext: true,
            errorMessage: error,
            items: [_setoran('Siti', _now)],
          ),
        );
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

  group('visible Edit and Hapus on an expanded phone setoran (PIL-484)', () {
    const editKey = ValueKey('aktivitas-edit');
    const hapusKey = ValueKey('aktivitas-hapus');

    void phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      api.on(
        'GET',
        '/api/v1/transaksi/t1',
        json: {
          'nasabah_nama': 'Ani',
          'total_nilai': '5000',
          'saldo_setelah_transaksi': '42000',
          'items': [],
        },
      );
    }

    // Scope above the app so sheets and dialogs on the root navigator keep
    // their providers, as in the real app.
    Future<void> pumpRows(
      WidgetTester tester,
      List<ActivitasEntity> items, {
      bool isWeb = false,
      Size size = const Size(390, 844),
    }) async {
      phone(tester, size: size);
      feedNotifier = _TestRiwayatNotifier(
          RiwayatAktivitasState(status: AktivitasStatus.loaded, items: items));
      await tester.pumpWidget(withTransaksiProviders(
        riwayat: feedNotifier,
        transaksi: transaksi,
        harga: buildHargaNotifier(api),
        analytics: analytics,
        child: MaterialApp(
          home: Scaffold(
            body: AktivitasListView(now: () => _now, isWeb: isWeb),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('are hidden until the card is expanded', (tester) async {
      await pumpRows(tester, [_setoran('Ani', _now, id: 't1')]);

      expect(find.byKey(editKey), findsNothing);
      expect(find.byKey(hapusKey), findsNothing);
    });

    testWidgets('show side by side above Rincian without overflow', (
      tester,
    ) async {
      await pumpRows(tester, [_setoran('Ani', _now, id: 't1')]);

      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: find.byKey(editKey), matching: find.text('Edit')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(hapusKey), matching: find.text('Hapus')),
        findsOneWidget,
      );
      final edit = tester.getRect(find.byKey(editKey));
      final hapus = tester.getRect(find.byKey(hapusKey));
      expect(edit.top, hapus.top);
      expect(edit.right, lessThan(hapus.left));
      expect(hapus.right, lessThanOrEqualTo(390));
      expect(edit.left, greaterThanOrEqualTo(0));
      final detail = tester.getRect(find.byType(AktivitasSetoranDetail));
      expect(edit.bottom, lessThanOrEqualTo(detail.top));
    });

    testWidgets('Edit opens the edit setoran form', (tester) async {
      await pumpRows(tester, [_setoran('Ani', _now, id: 't1')]);
      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(editKey));
      await tester.pumpAndSettle();

      expect(find.byType(EditSetoranSheet), findsOneWidget);
    });

    testWidgets('Hapus opens the batalkan dialog', (tester) async {
      await pumpRows(tester, [_setoran('Ani', _now, id: 't1')]);
      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(hapusKey));
      await tester.pumpAndSettle();

      expect(find.byType(BatalkanSetoranDialog), findsOneWidget);
    });

    testWidgets('are not offered on a pencairan row', (tester) async {
      phone(tester);
      await pumpList(
          tester,
          RiwayatAktivitasState(
              status: AktivitasStatus.loaded,
              items: [_pencairan('Budi', _now)]));

      await tester.tap(find.text('Budi'));
      await tester.pumpAndSettle();

      expect(find.byKey(editKey), findsNothing);
      expect(find.byKey(hapusKey), findsNothing);
    });

    testWidgets('are not offered on a voided setoran', (tester) async {
      final voided = ActivitasEntity.fromTransaksi(
        TransaksiEntity(
          id: 't1',
          initials: 'AB',
          avatarColor: Colors.green.shade100,
          textColor: Colors.green,
          name: 'Ani',
          subtitle: '',
          amount: '+Rp 5.000',
          isWaSuccess: true,
          time: '10:00',
          balance: 'Rp 5.000',
          items: const [],
          tanggal: _now,
          isDibatalkan: true,
        ),
      );
      await pumpRows(tester, [voided]);

      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();

      expect(find.byKey(editKey), findsNothing);
      expect(find.byKey(hapusKey), findsNothing);
    });

    testWidgets('disappear while selecting and hold-to-select still works', (
      tester,
    ) async {
      await pumpRows(tester, [
        _setoran('Ani', _now, id: 't1'),
        _setoran('Budi', _now, id: 't2'),
      ]);
      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();
      expect(find.byKey(editKey), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Budi')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.up();
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AktivitasListView)),
      );
      expect(container.read(aktivitasSelectionProvider), {'t2'});
      expect(find.byKey(editKey), findsNothing);
      expect(find.byKey(hapusKey), findsNothing);
    });

    // The card buttons stand in for the table's Aksi column: they show exactly
    // when the table is not used, decided by layout width and not by platform.
    final cardActions = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Aksi setoran');

    testWidgets('show on a compact web layout, above Rincian', (tester) async {
      await pumpRows(tester, [_setoran('Ani', _now, id: 't1')], isWeb: true);

      expect(find.byType(AktivitasTable), findsNothing);
      await tester.tap(find.text('Ani'));
      await tester.pumpAndSettle();

      expect(cardActions, findsOneWidget);
      expect(find.byKey(editKey), findsOneWidget);
      expect(find.byKey(hapusKey), findsOneWidget);
      expect(
          tester.getRect(find.byKey(editKey)).bottom,
          lessThanOrEqualTo(
              tester.getRect(find.byType(AktivitasSetoranDetail)).top));
    });

    for (final isWeb in [true, false]) {
      testWidgets(
          'are replaced by the table Aksi column on a wide layout '
          '(isWeb: $isWeb)', (tester) async {
        await pumpRows(tester, [_setoran('Ani', _now, id: 't1')],
            isWeb: isWeb, size: const Size(1200, 900));

        expect(find.byType(AktivitasTable), findsOneWidget);
        expect(find.byKey(editKey), findsOneWidget);
        expect(find.byKey(hapusKey), findsOneWidget);

        await tester.tap(find.text('Ani'));
        await tester.pumpAndSettle();

        expect(find.byType(AktivitasSetoranDetail), findsOneWidget);
        expect(cardActions, findsNothing);
        // Only the table's own pair, never a second one from the card.
        expect(find.byKey(editKey), findsOneWidget);
        expect(find.byKey(hapusKey), findsOneWidget);
      });
    }
  });
}
