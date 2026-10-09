import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/dashboard/stats';

void main() {
  late StubApi api;
  late DashboardCubit cubit;

  setUp(() {
    api = StubApi();
    cubit = buildDashboardCubit(api);
  });

  tearDown(() => cubit.close());

  test('loads the month figures from the stats endpoint', () async {
    api.on('GET', _path, json: {
      'total_nilai_bulan_ini': '1500000.00',
      'nasabah_aktif': 42,
      'total_sampah_kg_bulan_ini': '123.5',
      'transaksi_bulan_ini': 7,
    });

    await cubit.loadStats();

    expect(cubit.state.isLoaded, isTrue);
    expect(cubit.state.totalKasBulanIni, 1500000);
    expect(cubit.state.totalNasabahAktif, 42);
    expect(cubit.state.totalSampahKg, 123.5);
    expect(cubit.state.totalTransaksi, 7);
  });

  test('missing figures read as zero', () async {
    api.on('GET', _path, json: <String, dynamic>{});

    await cubit.loadStats();

    expect(cubit.state.isLoaded, isTrue);
    expect(cubit.state.totalKasBulanIni, 0);
    expect(cubit.state.totalSampahKg, 0);
  });

  test('a failure keeps the previous figures and carries the message',
      () async {
    api.on('GET', _path, json: {'nasabah_aktif': 3});
    await cubit.loadStats();
    api.on('GET', _path, status: 403, json: {'error': 'Tidak diizinkan'});

    await cubit.loadStats();

    expect(cubit.state.status, DashboardStatus.error);
    expect(cubit.state.error, 'Tidak diizinkan');
    expect(cubit.state.isLoaded, isFalse);
  });

  test('a silent refresh does not flash the loading state', () async {
    api.on('GET', _path, json: {'nasabah_aktif': 3});
    await cubit.loadStats();
    api.on('GET', _path, json: {'nasabah_aktif': 4});
    final statuses = <DashboardStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));

    await cubit.loadStats(silent: true);
    await pumpEventQueue();
    await sub.cancel();

    expect(statuses, [DashboardStatus.loaded]);
  });

  test('a normal reload shows loading first', () async {
    api.on('GET', _path, json: {});
    final statuses = <DashboardStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));

    await cubit.loadStats();
    await pumpEventQueue();
    await sub.cancel();

    expect(statuses, [DashboardStatus.loading, DashboardStatus.loaded]);
  });

  test('a dropped connection is an error state', () async {
    api.fail('GET', _path, DioExceptionType.connectionTimeout);

    await cubit.loadStats();

    expect(cubit.state.error, 'Connection Timeout');
  });

  test('reset clears the figures', () async {
    api.on('GET', _path, json: {'nasabah_aktif': 3});
    await cubit.loadStats();

    cubit.reset();

    expect(cubit.state, const DashboardState());
  });

  test('copyWith overrides only what it is given', () {
    const state = DashboardState(totalTransaksi: 2);

    final next = state.copyWith(totalKasBulanIni: 9);

    expect(next.totalTransaksi, 2);
    expect(next.totalKasBulanIni, 9);
  });
}
