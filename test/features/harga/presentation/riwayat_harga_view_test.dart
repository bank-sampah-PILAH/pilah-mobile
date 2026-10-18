import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/riwayat_harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/riwayat_harga_page.dart';

import '../../../support/stub_api.dart';

const _path = '/api/v1/jenis-sampah/j-1/harga';

Map<String, dynamic> _versi(
  String harga,
  String mulai,
  String status, {
  String? oleh = 'Ibu Sari',
}) =>
    {
      'id': 1,
      'harga_per_kg': harga,
      'satuan': 'kg',
      'berlaku_mulai': mulai,
      'dibuat_oleh': oleh,
      'status': status,
    };

void main() {
  late StubApi api;

  setUp(() => api = StubApi());

  Future<void> pumpView(WidgetTester tester) async {
    final repository =
        HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RiwayatHargaCubit(GetRiwayatHargaUseCase(repository)),
          child: const RiwayatHargaView(jenisId: 'j-1', namaJenis: 'Botol PET'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'lists each version with its price, local start, author and status',
      (tester) async {
    api.on('GET', _path, json: {
      'results': [
        _versi('5500.00', '2026-10-14T17:00:00Z', 'terjadwal'),
        _versi('5000.00', '2026-10-14T17:00:00Z', 'digantikan'),
        _versi('4000.00', '2026-10-01T02:30:00Z', 'berlaku'),
        _versi('3500.00', '2026-09-01T03:00:00Z', 'sebelumnya', oleh: null),
      ],
    });

    await pumpView(tester);

    expect(find.text('Botol PET'), findsOneWidget);
    for (final (harga, status) in [
      ('Rp 5.500 / kg', 'Terjadwal'),
      ('Rp 5.000 / kg', 'Digantikan'),
      ('Rp 4.000 / kg', 'Berlaku sekarang'),
      ('Rp 3.500 / kg', 'Sebelumnya'),
    ]) {
      expect(find.text(harga), findsOneWidget, reason: harga);
      expect(find.text(status), findsOneWidget, reason: status);
    }
    final mulai = DateTime.parse('2026-10-01T02:30:00Z').toLocal();
    expect(find.text('Mulai ${formatTanggalJamId(mulai)}'), findsOneWidget);
    expect(find.text('Dicatat oleh Ibu Sari'), findsNWidgets(3));
    expect(find.text('Harga awal dari data lama'), findsOneWidget);
  });

  testWidgets('shows how much each version moved from the one before',
      (tester) async {
    api.on('GET', _path, json: {
      'results': [
        _versi('5500.00', '2026-10-14T17:00:00Z', 'terjadwal'),
        _versi('5000.00', '2026-10-14T17:00:00Z', 'digantikan'),
        _versi('4000.00', '2026-10-01T02:30:00Z', 'berlaku'),
        _versi('3500.00', '2026-09-01T03:00:00Z', 'sebelumnya', oleh: null),
        _versi('3600.00', '2026-08-01T03:00:00Z', 'sebelumnya'),
      ],
    });

    await pumpView(tester);

    expect(find.text('▲ Rp 1.500 (+38%)'), findsOneWidget,
        reason: 'compared with 4.000, skipping the replaced 5.000');
    expect(find.text('▲ Rp 500 (+14%)'), findsOneWidget);
    expect(find.text('▼ Rp 100 (-3%)'), findsOneWidget);
    expect(find.textContaining('▲'), findsNWidgets(2));
    expect(find.textContaining('▼'), findsOneWidget,
        reason: 'the replaced version and the very first one have no change');
  });

  testWidgets('says so when the jenis has no price history yet',
      (tester) async {
    api.on('GET', _path, json: {'results': <Object>[]});

    await pumpView(tester);

    expect(find.text('Belum Ada Riwayat Harga'), findsOneWidget);
  });

  testWidgets('a failed load says why and can be retried', (tester) async {
    api.fail('GET', _path);
    await pumpView(tester);

    expect(find.text('Coba lagi'), findsOneWidget);
    api.on('GET', _path, json: {
      'results': [_versi('4000.00', '2026-10-01T02:30:00Z', 'berlaku')],
    });
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Rp 4.000 / kg'), findsOneWidget);
  });

  testWidgets('the largest price and the widest badge fit a phone screen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    api.on('GET', _path, json: {
      'results': [_versi('999999999.00', '2026-10-01T02:30:00Z', 'berlaku')],
    });

    await pumpView(tester);

    expect(find.text('Rp 999.999.999 / kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a price with sen exactly as stored', (tester) async {
    // Harga per kg boleh bersen (mis. 3333.99); riwayat menampilkan nilai
    // yang tersimpan, bukan yang dibulatkan.
    api.on('GET', _path, json: {
      'results': [
        _versi('3333.99', '2026-10-01T02:30:00Z', 'berlaku'),
        _versi('3500.50', '2026-09-01T03:00:00Z', 'sebelumnya'),
      ],
    });

    await pumpView(tester);

    expect(find.text('Rp 3.333,99 / kg'), findsOneWidget);
    expect(find.text('Rp 3.500,50 / kg'), findsOneWidget);
  });
}
