import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/domain/entities/cari_bank_entities.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_cubit.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/pages/perbandingan_harga_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/perbandingan_harga_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _endpoint = '/api/v1/bank-sampah/harga-perbandingan';

void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    // The page resolves its cubit through the DI container itself.
    di.allowReassignment = true;
    di.registerSingleton<PerbandinganHargaCubit>(
        buildPerbandinganHargaCubit(api));
    addTearDown(() => di.unregister<PerbandinganHargaCubit>());
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
    expect(find.text('Jenis: Plastik PET (PLS-001)'), findsOneWidget);
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
  });

  testWidgets('a failing load shows the message', (tester) async {
    api.on('GET', _endpoint, status: 500, json: {});

    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('Gagal Memuat Perbandingan'), findsOneWidget);
  });
}
