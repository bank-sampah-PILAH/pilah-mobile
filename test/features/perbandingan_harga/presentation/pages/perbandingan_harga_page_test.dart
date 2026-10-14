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

  testWidgets('cancelling the sheet adds no bank and reloads nothing',
      (tester) async {
    api.on(
      'GET',
      _endpoint,
      json:
          perbandinganJson(rows: [hargaRow('b1', 'Bank A', harga: '3000.00')]),
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
    // The sheet itself fires its directory request; snapshot after it opened.
    final permintaanSaatSheet = api.requests.length;
    // Dismiss without picking: the sheet is scroll-controlled and floats
    // from the top; the far bottom-left barrier is outside its surface.
    await tester.tapAt(Offset(5, tester.view.physicalSize.height / 1));
    await tester.pumpAndSettle();

    expect(
      api.requests.length,
      permintaanSaatSheet,
      reason: 'a cancelled pick must not trigger a reload',
    );
    expect(find.byKey(const Key('perbandingan_baris_b2')), findsNothing);
  });

  testWidgets('the picker sheet searches, hides picks, and reports failure',
      (tester) async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [hargaRow('b1', 'Bank A', harga: '3000.00')]),
    );
    // Opening the sheet: two matching banks; already-picked b1 is hidden.
    api.on(
      'GET',
      _directory,
      json: bankSampahPage([bankRow('b1', 'Bank A'), bankRow('b2', 'Bank B')]),
    );

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('perbandingan_tambah_bank')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('perbandingan_picker_bank_b1')), findsNothing);
    expect(find.byKey(const Key('perbandingan_picker_bank_b2')), findsOneWidget);

    // A keyword refetches the directory: anything not matching disappears.
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    await tester.enterText(find.byKey(const Key('perbandingan_picker_cari')),
        'tidak-ada');
    await tester.pumpAndSettle();

    // The empty state replaced the list.
    expect(find.byKey(const Key('perbandingan_picker_bank_b2')), findsNothing);
    expect(find.text('Tidak Ada Bank Sampah Lain'), findsOneWidget);

    // A directory failure inside the sheet shows the error card, not a blank.
    api.on('GET', _directory, status: 500, json: {});
    await tester
        .enterText(find.byKey(const Key('perbandingan_picker_cari')), 'Bank B');
    await tester.pumpAndSettle();

    expect(find.text('Gagal Memuat Daftar Bank'), findsOneWidget);
  });

  testWidgets('a price row without a parseable number shows the note',
      (tester) async {
    // harga_tidak_tersedia false but harga_per_kg unparsable: the double
    // tryParse fails and falls through to the unavailable note.
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        {
          'bank_sampah_id': 'b1',
          'nama': 'Bank A',
          'kota': 'Depok',
          'harga_per_kg': 'gratis-saja',
          'berlaku_mulai': null,
          'harga_tidak_tersedia': false,
          'alasan': null,
        },
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Harga belum tersedia'), findsOneWidget);
  });

  testWidgets('a nameless row shows the anonymous label', (tester) async {
    // Backend's unknown-bank fallback carries an empty nama; a null nama (an
    // older envelope) is the branch the anonymous label actually covers.
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        {
          'bank_sampah_id': 'b9',
          'nama': null,
          'kota': '',
          'harga_per_kg': null,
          'berlaku_mulai': null,
          'harga_tidak_tersedia': true,
          'alasan': 'bukan_bank_bisa_gabung',
        },
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('(bank tidak bisa dibandingkan)'), findsOneWidget);
  });

  testWidgets('an unavailable row without berlaku_mulai skips the date line',
      (tester) async {
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
        hargaRow('b2', 'Bank B', alasan: 'belum_ada_harga'),
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    // Only the priced row carries a Berlaku line.
    expect(find.textContaining('Berlaku '), findsOneWidget);
  });

  testWidgets('ten banks reach the cap; the eleventh tap snackbar only',
      (tester) async {
    // The endpoint answer is static: rows for b1 already in the list, the
    // rest are whatever the sheet picked — only the cap path matters here.
    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [
        hargaRow('b1', 'Bank A', harga: '3000.00'),
      ]),
    );

    await pump(tester);
    await tester.pumpAndSettle();

    var tambahan = 0;
    while (tambahan < 9) {
      api.on(
        'GET',
        _directory,
        json: bankSampahPage(
          [bankRow('bX$tambahan', 'Bank X$tambahan')],
        ),
      );
      await tester.tap(find.byKey(const Key('perbandingan_tambah_bank')));
      await tester.pumpAndSettle();
      await tester.tap(
          find.byKey(Key('perbandingan_picker_bank_bX$tambahan')));
      await tester.pumpAndSettle();
      tambahan += 1;
    }

    // Cap reached: the next tap shows the snackbar instead of the sheet.
    await tester.tap(find.byKey(const Key('perbandingan_tambah_bank')));
    await tester.pump();
    expect(find.text('Maksimal 10 bank dalam satu perbandingan.'),
        findsOneWidget);
    expect(find.byKey(const Key('perbandingan_picker_cari')), findsNothing);
  });

  testWidgets('the seed construct is const and the sheet lists separators',
      (tester) async {
    // Ctor coverage: the seed the detail page pushes with.
    const PerbandinganSeed(
      jenisSampahId: 'j1',
      bankAsalId: 'b1',
      bankAsalNama: 'Bank A',
      layananAsal: <LayananEntity>[],
    );

    api.on(
      'GET',
      _endpoint,
      json: perbandinganJson(rows: [hargaRow('b1', 'Bank A', harga: '3000.00')]),
    );
    // The sheet answers with TWO banks so its ListView's separator builds.
    api.on(
      'GET',
      _directory,
      json: bankSampahPage([bankRow('b2', 'Bank B'), bankRow('b3', 'Bank C')]),
    );

    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('perbandingan_tambah_bank')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('perbandingan_picker_bank_b2')), findsOneWidget);
    expect(find.byKey(const Key('perbandingan_picker_bank_b3')), findsOneWidget);
  });
}
