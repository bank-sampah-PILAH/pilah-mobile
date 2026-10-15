import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/cari_bank/data/datasources/cari_bank_remote_data_source.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_sampah_detail_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

const _detail = '/api/v1/bank-sampah/b1';

void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    di.allowReassignment = true;
    di.registerLazySingleton<CariBankRemoteDataSource>(
        () => CariBankRemoteDataSourceImpl(api.network));
    addTearDown(() => di.unregister<CariBankRemoteDataSource>());
  });

  testWidgets('shows profile, coordinates, and the active layanan',
      (tester) async {
    api.on('GET', _detail,
        json: bankDetailJson(layanan: [
          layananJson('K-1', 'Kardus', '1500.00'),
          layananJson('P-2', 'Botol', '2000.00'),
        ]));

    await pumpRouted(
      tester,
      const BankSampahDetailPage(bankSampahId: 'b1'),
      size: const Size(600, 1200),
    );
    await tester.pumpAndSettle();

    // The nama shows in both the app bar and the detail header.
    expect(find.text('Bank Garis'), findsWidgets);
    expect(find.byKey(const Key('detail_bank_buka_peta')), findsOneWidget);
    expect(find.text('K-1 · Kardus'), findsOneWidget);
    expect(find.text('Rp 1.500/kg'), findsOneWidget);
    expect(find.text('Rp 2.000/kg'), findsOneWidget);
  });

  testWidgets('a failing detail shows the message with a retry',
      (tester) async {
    api.on('GET', _detail, status: 404, json: {'detail': 'Tidak ditemukan.'});

    await pumpRouted(
      tester,
      const BankSampahDetailPage(bankSampahId: 'b1'),
      size: const Size(600, 1200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coba Lagi'), findsOneWidget);

    api.on('GET', _detail,
        json:
            bankDetailJson(layanan: [layananJson('K-1', 'Kardus', '1500.00')]));
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('K-1 · Kardus'), findsOneWidget);
  });

  testWidgets('a bank without coordinates shows no map button', (tester) async {
    api.on(
      'GET',
      _detail,
      // lat/lng omitted: the entity's fallbacks take over as no-location.
      json: bankDetailJson(layanan: [])
        ..remove('latitude')
        ..remove('longitude'),
    );

    await pumpRouted(
      tester,
      const BankSampahDetailPage(bankSampahId: 'b1'),
      size: const Size(600, 1200),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_bank_buka_peta')), findsNothing);
    // Empty layanan: the note replaces the list and there is no comparison
    // button either.
    expect(find.text('Belum ada jenis sampah aktif pada bank ini.'),
        findsOneWidget);
    expect(find.byKey(const Key('detail_bank_bandingkan_harga')), findsNothing);
  });

  testWidgets('Buka peta pushes the full-screen lokasi map', (tester) async {
    api.on(
      'GET',
      _detail,
      json: bankDetailJson(layanan: [layananJson('K-1', 'Kardus', '1500.00')]),
    );

    await pumpRouted(
      tester,
      const BankSampahDetailPage(bankSampahId: 'b1'),
      size: const Size(600, 1200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail_bank_buka_peta')));
    await tester.pumpAndSettle();

    // The map page pushed: its title and the pin are visible.
    expect(find.text('Lokasi Bank Sampah'), findsOneWidget);
    expect(find.byKey(const Key('detail_bank_marker')), findsOneWidget);
  });

  testWidgets('a deskripsi row shows under the kode line when present',
      (tester) async {
    api.on(
      'GET',
      _detail,
      json: bankDetailJson(
        layanan: [
          {
            ...layananJson('K-1', 'Kardus', '1500.00'),
            'deskripsi': 'Kardus bekas olahan'
          },
        ],
      ),
    );

    await pumpRouted(
      tester,
      const BankSampahDetailPage(bankSampahId: 'b1'),
      size: const Size(600, 1200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kardus bekas olahan'), findsOneWidget);
  });

  testWidgets('Bandingkan Harga pushes the comparison page with the seed',
      (tester) async {
    api.on(
      'GET',
      _detail,
      json: bankDetailJson(layanan: [layananJson('K-1', 'Kardus', '1500.00')]),
    );

    await pumpRouted(
      tester,
      const BankSampahDetailPage(bankSampahId: 'b1'),
      extraRoutes: [
        '/perbandingan-harga',
      ],
      size: const Size(600, 1200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('detail_bank_bandingkan_harga')));
    await tester.pumpAndSettle();

    // The comparison page route rendered its stub line.
    expect(
      find.textContaining('route:/perbandingan-harga'),
      findsOneWidget,
      reason: 'the seed push landed on the registered extra route',
    );
  });
}
