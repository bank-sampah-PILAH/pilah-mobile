import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';

import '../../../../support/stub_api.dart';
import '../../../../support/transaksi_support.dart';

const _path = '/api/v1/transaksi';

String _iso(DateTime d) => d.toUtc().toIso8601String();

Map<String, dynamic> _row(String id, String nama,
        {DateTime? tanggal,
        String? jenis = 'Plastik',
        String wa = 'terkirim',
        Object? berat = '2.5',
        Object? total = '12500'}) =>
    {
      'id': id,
      'nasabah_nama': nama,
      'jenis_sampah_utama': jenis,
      'total_berat_kg': berat,
      'total_nilai': total,
      'status_wa': wa,
      if (tanggal != null) 'tanggal': _iso(tanggal),
    };

void main() {
  late StubApi api;
  late TransaksiCubit cubit;
  final now = DateTime.now();

  setUp(() {
    api = StubApi();
    cubit = buildTransaksiCubit(api);
  });

  tearDown(() => cubit.close());

  test('groups the list into day buckets with display fields', () async {
    api.on('GET', _path, json: {
      'results': [
        _row('1', 'Budi Santoso', tanggal: now),
        _row('2', 'Siti',
            tanggal: now.subtract(const Duration(days: 1)), wa: 'gagal'),
        _row('3', 'Andi',
            tanggal: now.subtract(const Duration(days: 5)), jenis: null),
        _row('4', 'Tanpa Tanggal'),
        {...(_row('5', 'Dua')), 'nasabah_inisial': 'ZZ'},
        _row('6', 'Bud', tanggal: now),
      ],
    });

    await cubit.loadTransaksi();

    final loaded = cubit.state as TransaksiLoaded;
    expect(loaded.transaksiList.map((g) => g.header),
        ['HARI INI', 'KEMARIN', '5 HARI LALU', 'LAINNYA']);
    final today = loaded.transaksiList.first.transactions;
    expect(today.map((t) => t.id), ['1', '6']);
    expect(today.first.amount, '+Rp 12.500');
    expect(today.first.subtitle, 'Plastik • 2,5 kg');
    expect(today.first.initials, 'BS');
    expect(today.first.isWaSuccess, isTrue);
    expect(today.first.time, matches(RegExp(r'^\d\d:\d\d$')));
    expect(loaded.transaksiList[1].transactions.single.isWaSuccess, isFalse);
    expect(loaded.transaksiList[2].transactions.single.subtitle, '2,5 kg');
    final lainnya = loaded.transaksiList[3].transactions;
    expect(lainnya.first.time, isNull);
    expect(lainnya.last.initials, 'ZZ');
    expect(api.last.query, {'periode': 'bulan_ini', 'page_size': '100'});
  });

  test('accepts a bare list response', () async {
    api.on('GET', _path, json: [_row('1', 'Budi', tanggal: now)]);

    await cubit.loadTransaksi();

    expect((cubit.state as TransaksiLoaded).transaksiList.single.header,
        'HARI INI');
  });

  test('a map without results is an empty list', () async {
    api.on('GET', _path, json: <String, dynamic>{});

    await cubit.loadTransaksi();

    expect((cubit.state as TransaksiLoaded).transaksiList, isEmpty);
  });

  test('search narrows by name, initials or subtitle', () async {
    api.on('GET', _path, json: {
      'results': [
        _row('1', 'Budi Santoso', tanggal: now),
        _row('2', 'Siti Aminah', tanggal: now, jenis: 'Kertas'),
      ],
    });
    await cubit.loadTransaksi();

    cubit.searchTransaksi('kertas');
    expect(
        (cubit.state as TransaksiLoaded)
            .transaksiList
            .single
            .transactions
            .map((t) => t.id),
        ['2']);
    cubit.searchTransaksi('bs');
    expect(
        (cubit.state as TransaksiLoaded)
            .transaksiList
            .single
            .transactions
            .single
            .id,
        '1');
    cubit.searchTransaksi('tidak ada');
    expect((cubit.state as TransaksiLoaded).transaksiList, isEmpty);
    expect(cubit.searchQuery, 'tidak ada');
  });

  test('changing the period refetches with the new filter', () async {
    api.on('GET', _path, json: {'results': []});

    cubit.setPeriode('bulan_ini');
    await pumpEventQueue();
    expect(api.requests, isEmpty, reason: 'same period is a no-op');

    cubit.setPeriode('bulan_lalu');
    await pumpEventQueue();
    expect(api.last.query['periode'], 'bulan_lalu');
    expect(cubit.periode, 'bulan_lalu');

    cubit.applyCustomRange(DateTime(2026, 1, 5), DateTime(2026, 2, 9));
    await pumpEventQueue();
    expect(api.last.query, {
      'periode': 'custom',
      'dari_tanggal': '2026-01-05',
      'sampai_tanggal': '2026-02-09',
      'page_size': '100',
    });
    final loaded = cubit.state as TransaksiLoaded;
    expect(loaded.dariTanggal, DateTime(2026, 1, 5));

    cubit.setPeriode('custom');
    await pumpEventQueue();
    expect(cubit.state, isA<TransaksiLoaded>());
  });

  test('a failing list is reported as an error state', () async {
    api.on('GET', _path, status: 500, json: {});

    await cubit.loadTransaksi();

    expect(cubit.state, const TransaksiError('Internal Server Error'));
  });

  test('add posts the items, trimmed note and idempotency key', () async {
    api.on('POST', _path, status: 201, json: {
      'id': 77,
      'total_nilai': '15000.00',
      'saldo_setelah_transaksi': '40000.40',
      'items': [{}, {}],
    });

    final result = await cubit.addTransaksi(TransaksiRequest(
      nasabahId: 'n1',
      items: [ItemSetoranRequest(jenisSampahId: 'j1', berat: 1.5)],
      idempotencyKey: 'key-1',
      catatan: '  halo ',
    ));

    expect(result.error, isNull);
    expect(result.created!.id, '77');
    expect(result.created!.totalNilai, 15000);
    expect(result.created!.saldoSetelah, 40000);
    expect(result.created!.itemCount, 2);
    expect(jsonDecode(api.last.body as String), {
      'nasabah_id': 'n1',
      'items': [
        {'jenis_sampah_id': 'j1', 'berat': 1.5}
      ],
      'catatan': 'halo',
    });
    expect(api.last.headers['Idempotency-Key'], 'key-1');
  });

  test('add omits a blank note and handles a sparse response', () async {
    api.on('POST', _path, status: 201, json: <String, dynamic>{});

    final result = await cubit.addTransaksi(TransaksiRequest(
      nasabahId: 'n1',
      items: [],
      idempotencyKey: 'k',
      catatan: '   ',
    ));

    expect(jsonDecode(api.last.body as String), {
      'nasabah_id': 'n1',
      'items': <dynamic>[],
    });
    expect(result.created!.id, '');
    expect(result.created!.totalNilai, 0);
    expect(result.created!.itemCount, 0);
  });

  test('add hands back the failure', () async {
    api.on('POST', _path, status: 422, json: {
      'errors': {
        'items': ['Berat harus positif']
      },
    });

    final result = await cubit.addTransaksi(
        TransaksiRequest(nasabahId: 'n1', items: [], idempotencyKey: 'k'));

    expect(result.created, isNull);
    expect(result.error!.displayMessage, 'Berat harus positif');
  });

  test('fetches a detail with formatted items', () async {
    api.on('GET', '$_path/t1', json: {
      'nasabah_nama': 'Budi',
      'total_nilai': '1234567',
      'saldo_setelah_transaksi': '-500',
      'status_wa': 'gagal',
      'items': [
        {
          'nama_sampah_snapshot': 'Botol',
          'berat': '1.25',
          'harga_snapshot': '2000',
          'subtotal': '2500',
        },
        <String, dynamic>{},
      ],
    });

    final detail = (await cubit.fetchTransaksiDetail('t1'))!;

    expect(detail.name, 'Budi');
    expect(detail.amountFormatted, 'Rp 1.234.567');
    expect(detail.balanceFormatted, 'Rp 500');
    expect(detail.waStatus, 'failed');
    expect(detail.items.first.jenis, 'Botol');
    expect(detail.items.first.berat, '1,25 kg');
    expect(detail.items.first.harga, 'Rp 2.000');
    expect(detail.items.last.jenis, '-');
  });

  test('a detail defaults missing fields and pending WA', () async {
    api.on('GET', '$_path/t1', json: <String, dynamic>{});

    final detail = (await cubit.fetchTransaksiDetail('t1'))!;

    expect(detail.name, '-');
    expect(detail.waStatus, 'pending');
    expect(detail.items, isEmpty);
  });

  test('a failed detail fetch yields null', () async {
    api.on('GET', '$_path/t1', status: 404, json: {});

    expect(await cubit.fetchTransaksiDetail('t1'), isNull);
  });

  test('resending WA flips the cached row without a reload', () async {
    api.on('GET', _path, json: {
      'results': [_row('1', 'Budi', tanggal: now, wa: 'gagal')],
    });
    await cubit.loadTransaksi();
    api.on('POST', '$_path/1/notify-wa',
        json: {'success': true, 'status_wa': 'terkirim'});
    final getCalls = api.requests.where((r) => r.method == 'GET').length;

    final result = await cubit.resendWa('1');

    expect(result.success, isTrue);
    final row = (cubit.state as TransaksiLoaded)
        .transaksiList
        .single
        .transactions
        .single;
    expect(row.isWaSuccess, isTrue);
    expect(api.requests.where((r) => r.method == 'GET').length, getCalls);

    // Already sent: nothing changes, nothing re-emitted.
    final states = <TransaksiState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.resendWa('1');
    await cubit.resendWa('unknown');
    await pumpEventQueue();
    await sub.cancel();
    expect(states, isEmpty);
  });

  test('resending WA reports the backend message on failure', () async {
    api.on('POST', '$_path/1/notify-wa',
        status: 400, json: {'error': 'Nomor tidak valid'});

    final result = await cubit.resendWa('1');

    expect(result.success, isFalse);
    expect(result.error, 'Nomor tidak valid');
  });

  test('export returns bytes and the server filename', () async {
    api.onBytes('GET', '$_path/export', [
      1,
      2,
      3
    ], headers: {
      'content-disposition': ['attachment; filename="laporan.xlsx"'],
    });

    final result = await cubit.exportTransaksi();

    expect(result.error, isNull);
    expect(result.export!.bytes, [1, 2, 3]);
    expect(result.export!.filename, 'laporan.xlsx');
    expect(api.last.query, {'periode': 'bulan_ini'});
  });

  test('export falls back to a generated filename', () async {
    api.onBytes('GET', '$_path/export', [9]);

    final result = await cubit.exportTransaksi();

    expect(result.export!.filename, startsWith('laporan_transaksi_'));
    expect(result.export!.filename, endsWith('.xlsx'));
  });

  test('export surfaces a decoded JSON error from the byte body', () async {
    api.onBytes(
        'GET', '$_path/export', utf8.encode('{"error":"Tidak ada data"}'));
    api.status('GET', '$_path/export', 400);

    final result = await cubit.exportTransaksi();

    expect(result.error, 'Tidak ada data');
  });

  test('export falls back to the generic handler for other failures', () async {
    api.onBytes('GET', '$_path/export', utf8.encode('not json'));
    api.status('GET', '$_path/export', 500);
    expect((await cubit.exportTransaksi()).error, 'Internal Server Error');

    api.onBytes('GET', '$_path/export', utf8.encode('[1]'));
    api.status('GET', '$_path/export', 500);
    expect((await cubit.exportTransaksi()).error, 'Internal Server Error');

    api.fail('GET', '$_path/export', DioExceptionType.connectionTimeout);
    expect((await cubit.exportTransaksi()).error, 'Connection Timeout');

    api.crash('GET', '$_path/export', StateError('boom'));
    expect((await cubit.exportTransaksi()).error, 'Error During Communication');
  });

  test('reset returns to the initial state and period', () async {
    api.on('GET', _path, json: {'results': []});
    cubit.setPeriode('minggu_ini');
    await pumpEventQueue();

    cubit.reset();

    expect(cubit.state, isA<TransaksiInitial>());
    expect(cubit.periode, 'bulan_ini');
    expect(cubit.searchQuery, '');
  });

  test('the "semua" filter asks for no date window', () {
    expect(const TransaksiFilter.semua(pageSize: 5).toQueryParams(),
        {'periode': 'semua'});
    expect(const TransaksiFilter(periode: 'custom').toQueryParams(),
        {'periode': 'custom'});
    expect(const TransaksiFilter().isCustom, isFalse);
  });

  test('non-Dio failures from the list are reported as general errors',
      () async {
    api.crash('GET', _path, const FormatException('bad'));

    await cubit.loadTransaksi();

    expect(cubit.state, isA<TransaksiError>());
  });

  test('states compare by value', () {
    expect(TransaksiInitial(), TransaksiInitial());
    expect(TransaksiLoading(), TransaksiLoading());
    expect(const TransaksiLoaded(transaksiList: []),
        const TransaksiLoaded(transaksiList: []));
  });
}
