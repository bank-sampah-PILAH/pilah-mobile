import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';

import '../../../../support/dashboard_support.dart';
import '../../../../support/stub_api.dart';

const _path = '/api/v1/dashboard/stats';

void main() {
  late StubApi api;
  late ProviderContainer container;
  late DashboardNotifier notifier;
  late DashboardState state;

  setUp(() {
    api = StubApi();
    notifier = buildDashboardNotifier(api);
    container = ProviderContainer(overrides: [
      dashboardProvider.overrideWith(() => notifier),
    ]);
    state = container.read(dashboardProvider);
    container.listen(dashboardProvider, (_, next) => state = next);
  });

  tearDown(() => container.dispose());

  test('loads the month figures from the stats endpoint', () async {
    api.on('GET', _path, json: {
      'total_nilai_bulan_ini': '1500000.00',
      'nasabah_aktif': 42,
      'total_sampah_kg_bulan_ini': '123.5',
      'transaksi_bulan_ini': 7,
    });

    await notifier.loadStats();

    expect(state.isLoaded, isTrue);
    expect(state.totalKasBulanIni, 1500000);
    expect(state.totalNasabahAktif, 42);
    expect(state.totalSampahKg, 123.5);
    expect(state.totalTransaksi, 7);
  });

  test('missing figures read as zero', () async {
    api.on('GET', _path, json: <String, dynamic>{});

    await notifier.loadStats();

    expect(state.isLoaded, isTrue);
    expect(state.totalKasBulanIni, 0);
    expect(state.totalSampahKg, 0);
  });

  test('a failure keeps the previous figures and carries the message',
      () async {
    api.on('GET', _path, json: {'nasabah_aktif': 3});
    await notifier.loadStats();
    api.on('GET', _path, status: 403, json: {'error': 'Tidak diizinkan'});

    await notifier.loadStats();

    expect(state.status, DashboardStatus.error);
    expect(state.error, 'Tidak diizinkan');
    expect(state.isLoaded, isFalse);
  });

  test('a silent refresh does not flash the loading state', () async {
    api.on('GET', _path, json: {'nasabah_aktif': 3});
    await notifier.loadStats();
    api.on('GET', _path, json: {'nasabah_aktif': 4});
    final statuses = <DashboardStatus>[];
    final sub = container.listen(dashboardProvider, (_, next) {
      statuses.add(next.status);
    });

    await notifier.loadStats(silent: true);
    sub.close();

    expect(statuses, [DashboardStatus.loaded]);
  });

  test('a normal reload shows loading first', () async {
    api.on('GET', _path, json: {});
    final statuses = <DashboardStatus>[];
    final sub = container.listen(dashboardProvider, (_, next) {
      statuses.add(next.status);
    });

    await notifier.loadStats();
    sub.close();

    expect(statuses, [DashboardStatus.loading, DashboardStatus.loaded]);
  });

  test('a dropped connection is an error state', () async {
    api.fail('GET', _path, DioExceptionType.connectionTimeout);

    await notifier.loadStats();

    expect(state.error, 'Connection Timeout');
  });

  test('reset clears the figures', () async {
    api.on('GET', _path, json: {'nasabah_aktif': 3});
    await notifier.loadStats();

    notifier.reset();

    expect(state, const DashboardState());
  });

  test('copyWith overrides only what it is given', () {
    const before = DashboardState(totalTransaksi: 2);

    final next = before.copyWith(totalKasBulanIni: 9);

    expect(next.totalTransaksi, 2);
    expect(next.totalKasBulanIni, 9);
  });
}
