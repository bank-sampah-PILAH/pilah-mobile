import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_cubit.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/pages/perbandingan_harga_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/perbandingan_harga_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _endpoint = '/api/v1/bank-sampah/harga-perbandingan';
const _directory = '/api/v1/bank-sampah';

void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    // The page resolves its cubit through the DI container itself.
    di.allowReassignment = true;
    di.registerSingleton<PerbandinganHargaCubit>(
        buildPerbandinganHargaCubit(api));
    // The add-bank sheet resolves the cari_bank data source the same way.
    di.registerSingleton<CariBankRemoteDataSource>(
        CariBankRemoteDataSourceImpl(api.network));
    addTearDown(() => di.unregister<PerbandinganHargaCubit>());
    addTearDown(() => di.unregister<CariBankRemoteDataSource>());
  });

  Future<void> pump(WidgetTester tester) => pumpRouted(
        tester,
        PerbandinganHargaPage(
          jenisSampahId: 'j1',
          bankAsalId: 'b1',
          bankAsalNama: 'Bank A',
          layananAsal: const [
            LayananEntity(
              id: 'j1',
              kode: 'PLS-001',
              namaSampah: 'Plastik PET',
              kategori: 'plastik',
              deskripsi: '',
              hargaPerKg: '3000.00',
              satuan: 'kg',
            ),
            LayananEntity(
              id: 'j2',
              kode: 'KRS-001',
              namaSampah: 'Kardus',
              kategori: 'kertas',
              deskripsi: '',
              hargaPerKg: '1200.00',
              satuan: 'kg',
            ),
          ],
        ),
        size: const Size(600, 1200),
      );

  testWidgets('renders the requested order with rupiah rows', (tester) async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
        hargaRow('b2', 'Bank B', harga: '2500.00'),
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Rp 3.000'), findsOneWidget);
    expect(find.text('Rp 2.500'), findsOneWidget);
    expect(find.byKey(const Key('perbandingan_baris_b1')), findsOneWidget);
    // PIL-309 issue text: nominal, satuan, and waktu berlaku all shown.
    expect(find.text('Satuan: kg'), findsOneWidget);
    expect(find.textContaining('Berlaku '), findsNWidgets(2));
  });

  testWidgets('an unavailable price shows thebelum-tersedia note',
      (tester) async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
        hargaRow('b2', 'Bank B', alasan: 'tanpa_jenis'),
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Harga belum tersedia'), findsOneWidget);
    expect(find.text('Rp 2.500'), findsNothing);
    // Unavailable rows carry no berlaku_mulai.
    expect(find.textContaining('Berlaku '), findsOneWidget);
  });

  testWidgets('a failing load shows the message', (tester) async {
    api.on('GET', _endpoint, status: 500, json: {});

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Gagal Memuat Perbandingan'), findsOneWidget);
  });

  testWidgets('switching jenis reloads with the new jenis_sampah_id',
      (tester) async {
    api.on(
      'GET',
      _endpoint,
      json:
          perbandinganJson(rows: [hargaRow('b1', 'Bank A', harga: '3000.00')]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KRS-001 · Kardus').last);
    await tester.pumpAndSettle();

    expect(api.requests.last.query['jenis_sampah_id'], 'j2');
    expect(api.requests.last.query['bank_ids'], 'b1');
  });

  testWidgets('adding a bank through the sheet reloads with both ids',
      (tester) async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
        hargaRow('b2', 'Bank B', harga: '2500.00'),
      ]),
    );
    api.on(
      'GET',
      _directory,
      json: bankSampahPage([bankRow('b2', 'Bank B')]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('perbandingan_tambah_bank')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('perbandingan_picker_bank_b2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('perbandingan_baris_b2')), findsOneWidget);
    expect(api.requests.last.query['bank_ids'], 'b1,b2');
    // Already-compared banks no longer appear in the sheet.
    expect(find.byKey(const Key('perbandingan_picker_bank_b1')), findsNothing);
  });
}
