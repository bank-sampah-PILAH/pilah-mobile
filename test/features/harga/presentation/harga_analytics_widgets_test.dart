import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/riwayat_harga_page.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/riwayat_harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../support/fake_analytics_client.dart';
import '../../../support/harga_support.dart';
import '../../../support/pump_app.dart';
import '../../../support/stub_api.dart';

HargaEntity _existing({bool active = true}) => HargaEntity(
      id: 'h1',
      kodeSampah: 'PLS-001',
      name: 'Botol PET',
      price: 2500,
      priceFormatted: 'Rp 2500',
      category: 'plastik',
      subtitle: 'bening',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: active,
    );

Map<String, dynamic> _row(String id, String nama, String kategori) => {
      'id': id,
      'kode': 'K-$id',
      'nama_sampah': nama,
      'kategori': kategori,
      'deskripsi': 'desk $nama',
      'harga_per_kg': '2500',
      'is_active': true,
    };

void main() {
  late StubApi api;
  late HargaNotifier notifier;
  late FakeAnalyticsClient analytics;

  setUp(() {
    api = StubApi();
    analytics = FakeAnalyticsClient();
    notifier = buildHargaNotifier(api);
    api.on('GET', '/api/v1/jenis-sampah', json: {
      'results': [
        _row('1', 'Botol PET', 'plastik'),
        _row('2', 'Kardus', 'kertas'),
      ],
    });
  });

  Widget scoped(Widget child) => ProviderScope(
        overrides: [analyticsClientProvider.overrideWithValue(analytics)],
        child: child,
      );

  List<String> names() => analytics.events.map((e) => e.name).toList();

  Future<void> openSheet(WidgetTester tester, {HargaEntity? initial}) async {
    await pumpRouted(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => scoped(withHargaProvider(
                  notifier,
                  TambahJenisSampahBottomSheet(initialData: initial),
                )),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      size: const Size(800, 2000),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> fillNew(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'NEW-1');
    await tester.enterText(fields.at(1), 'Kardus Tebal');
    await tester.enterText(fields.at(3), '1500');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kertas').last);
    await tester.pumpAndSettle();
  }

  group('the form', () {
    testWidgets('opening it for a new jenis says so', (tester) async {
      await openSheet(tester);

      expect(names(), ['harga_form_dibuka']);
      expect(analytics.events.single.properties['mode'], 'baru');
    });

    testWidgets('saving a new jenis sends the event without name or price',
        (tester) async {
      api.on('POST', '/api/v1/jenis-sampah', status: 201, json: {});
      await openSheet(tester);
      await fillNew(tester);

      await tester.tap(find.text('Simpan Jenis Sampah'));
      await pumpToast(tester);

      final saved = analytics.events.last;
      expect(saved.name, 'harga_disimpan');
      expect(saved.properties['mode'], 'baru');
      expect(saved.properties['harga_berubah'], false);
      expect(saved.properties['kategori'], 'kertas');
      expect(saved.properties['percobaan_ke'], 1);
      final everything = analytics.events.map((e) => e.properties).toString();
      expect(everything, isNot(contains('1500')));
      expect(everything, isNot(contains('Kardus')));
      expect(everything, isNot(contains('NEW-1')));
      await settleToasts(tester);
    });

    testWidgets('changing the price of an existing jenis says so',
        (tester) async {
      api.on('PUT', '/api/v1/jenis-sampah/h1', json: {});
      api.on('POST', '/api/v1/jenis-sampah/h1/harga', status: 201, json: {});
      await openSheet(tester, initial: _existing());
      await tester.enterText(find.byType(TextFormField).at(3), '3000');

      await tester.tap(find.text('Simpan Perubahan'));
      await pumpToast(tester);

      final saved = analytics.events.last;
      expect(saved.name, 'harga_disimpan');
      expect(saved.properties['mode'], 'ubah');
      expect(saved.properties['harga_berubah'], true);
      await settleToasts(tester);
    });

    testWidgets('closing the form without saving is reported as cancelled',
        (tester) async {
      await openSheet(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(names(), ['harga_form_dibuka', 'harga_dibatalkan']);
      expect(analytics.events.last.properties['percobaan_ke'], 0);
    });

    testWidgets('a saved jenis is not also reported as cancelled',
        (tester) async {
      api.on('POST', '/api/v1/jenis-sampah', status: 201, json: {});
      await openSheet(tester);
      await fillNew(tester);

      await tester.tap(find.text('Simpan Jenis Sampah'));
      await pumpToast(tester);
      await settleToasts(tester);
      await tester.pumpAndSettle();

      expect(names(), ['harga_form_dibuka', 'harga_disimpan']);
    });

    testWidgets('a refused save followed by leaving is a cancellation',
        (tester) async {
      api.on('POST', '/api/v1/jenis-sampah', status: 422, json: {
        'errors': {
          'kode': ['dipakai']
        }
      });
      await openSheet(tester);
      await fillNew(tester);
      await tester.tap(find.text('Simpan Jenis Sampah'));
      await pumpToast(tester);
      await settleToasts(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(names().last, 'harga_dibatalkan');
      expect(analytics.events.last.properties['percobaan_ke'], 1);
    });

    testWidgets('a save the server refused is not reported as saved',
        (tester) async {
      api.on('POST', '/api/v1/jenis-sampah', status: 422, json: {
        'errors': {
          'kode': ['dipakai']
        }
      });
      await openSheet(tester);
      await fillNew(tester);

      await tester.tap(find.text('Simpan Jenis Sampah'));
      await pumpToast(tester);

      expect(names(), isNot(contains('harga_disimpan')));
      await settleToasts(tester);
    });

    testWidgets('confirming a deactivation reports it, cancelling does not',
        (tester) async {
      api.on('PATCH', '/api/v1/jenis-sampah/h1/status', json: {});
      await openSheet(tester, initial: _existing());

      await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(names(), isNot(contains('harga_status_diubah')));

      await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Nonaktifkan'));
      await pumpToast(tester);

      final changed =
          analytics.events.where((e) => e.name == 'harga_status_diubah');
      expect(changed.single.properties, {'aksi': 'nonaktifkan'});
      await settleToasts(tester);
    });

    testWidgets('a failed status change is not reported', (tester) async {
      api.on('PATCH', '/api/v1/jenis-sampah/h1/status',
          status: 403, json: {'error': 'Tidak boleh'});
      await openSheet(tester, initial: _existing());

      await tester.tap(find.text('Nonaktifkan Jenis Sampah'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, Nonaktifkan'));
      await pumpToast(tester);

      expect(names(), isNot(contains('harga_status_diubah')));
      await settleToasts(tester);
    });
  });

  group('the page search', () {
    Future<void> openPage(WidgetTester tester) async {
      await pumpRouted(
        tester,
        scoped(withHargaProvider(notifier, const HargaPage(isWeb: false))),
        size: const Size(800, 1600),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('typing a word starts one session and reports it once settled',
        (tester) async {
      await openPage(tester);

      await tester.enterText(find.byType(TextField).first, 'k');
      await tester.enterText(find.byType(TextField).first, 'ka');
      await tester.enterText(find.byType(TextField).first, 'kar');
      await tester.pump(const Duration(milliseconds: 300));
      expect(names(), ['pencarian_dimulai']);

      await tester.pump(const Duration(seconds: 2));

      expect(names(), ['pencarian_dimulai', 'pencarian_hasil']);
      expect(analytics.events.last.properties, {
        'alur_id': analytics.events.first.properties['alur_id'],
        'area': 'harga',
        'jumlah_hasil_kelas': '1_5',
        'panjang_kueri_kelas': '3_5',
        'percobaan_ke': 1,
        'filter': 'aktif',
      });
      expect(analytics.events.map((e) => e.properties).toString(),
          isNot(contains('kar\'')));
    });

    testWidgets('a search with nothing found says so', (tester) async {
      await openPage(tester);

      await tester.enterText(find.byType(TextField).first, 'zzz');
      await tester.pump(const Duration(seconds: 2));

      expect(analytics.events.last.name, 'pencarian_hasil');
      expect(analytics.events.last.properties['jumlah_hasil_kelas'], '0');
    });

    testWidgets('one letter is not a search', (tester) async {
      await openPage(tester);

      await tester.enterText(find.byType(TextField).first, 'k');
      await tester.pump(const Duration(seconds: 2));

      expect(analytics.events, isEmpty);
    });

    testWidgets('clearing the words after results means giving up',
        (tester) async {
      await openPage(tester);
      await tester.enterText(find.byType(TextField).first, 'kar');
      await tester.pump(const Duration(seconds: 2));

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump(const Duration(seconds: 2));

      expect(names().last, 'pencarian_ditinggalkan');
      expect(analytics.events.last.properties['hasil_terakhir_kelas'], '1_5');
    });

    testWidgets('opening a row of the results ends the search', (tester) async {
      await openPage(tester);
      await tester.enterText(find.byType(TextField).first, 'kar');
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Kardus'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(names().last, 'pencarian_dipilih');
      expect(analytics.events.last.properties['posisi_hasil_kelas'], '1');
      expect(analytics.events.last.properties['area'], 'harga');
    });

    testWidgets('opening more rows after the search ended starts nothing',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpRouted(
        tester,
        scoped(withHargaProvider(notifier, const HargaPage(isWeb: true))),
        size: const Size(1600, 1000),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'ka');
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Kardus').first);
      await tester.pump(const Duration(milliseconds: 600));
      final before = names();

      await tester.tap(find.text('Kardus').first);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Kardus').first);
      await tester.pump(const Duration(seconds: 2));

      expect(before,
          ['pencarian_dimulai', 'pencarian_hasil', 'pencarian_dipilih']);
      expect(names(), before);
    });

    testWidgets('says which tab the results are from and reports a tab change',
        (tester) async {
      await openPage(tester);
      await tester.enterText(find.byType(TextField).first, 'kar');
      await tester.pump(const Duration(seconds: 2));
      expect(analytics.events.last.properties['filter'], 'aktif');

      await tester.tap(find.text('Tidak Aktif'));
      await tester.pump(const Duration(seconds: 2));

      expect(names(), [
        'pencarian_dimulai',
        'pencarian_hasil',
        'pencarian_hasil',
      ]);
      expect(analytics.events.last.properties['filter'], 'tidak_aktif');
      expect(analytics.events.last.properties['jumlah_hasil_kelas'], '0');
      expect(analytics.events.last.properties['percobaan_ke'], 2);
    });

    testWidgets('a tab change without words reports nothing', (tester) async {
      await openPage(tester);

      await tester.tap(find.text('Tidak Aktif'));
      await tester.pump(const Duration(seconds: 2));

      expect(analytics.events, isEmpty);
    });

    testWidgets('opening a row before the typing settled still reports the try',
        (tester) async {
      await openPage(tester);
      await tester.enterText(find.byType(TextField).first, 'kar');
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Kardus'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(names(), [
        'pencarian_dimulai',
        'pencarian_hasil',
        'pencarian_dipilih',
      ]);
      expect(analytics.events.last.properties['percobaan_ke'], 1);
    });
  });

  group('the price history', () {
    setUp(() {
      if (di.isRegistered<GetRiwayatHargaUseCase>()) {
        di.unregister<GetRiwayatHargaUseCase>();
      }
    });

    testWidgets('opening it is reported once', (tester) async {
      api.on('GET', '/api/v1/jenis-sampah/j-1/harga', json: {'results': []});
      final repository =
          HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network));
      await tester.pumpWidget(
        scoped(withRiwayatHargaProvider(
          RiwayatHargaNotifier(GetRiwayatHargaUseCase(repository)),
          const MaterialApp(
            home: RiwayatHargaView(jenisId: 'j-1', namaJenis: 'Botol PET'),
          ),
        )),
      );
      await tester.pumpAndSettle();

      expect(names(), ['harga_riwayat_dibuka']);
    });
  });
}
