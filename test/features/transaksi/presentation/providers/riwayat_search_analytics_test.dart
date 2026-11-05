import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_page.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';

import '../../../../support/fake_analytics_client.dart';

class _Feed extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

ActivitasEntity _setoran(String id) =>
    ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: id,
      initials: 'BU',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: 'Nasabah $id',
      subtitle: 'Botol PET • 2 kg',
      amount: '+Rp 4.000',
      isWaSuccess: false,
      time: '10:00',
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 10, 5, 10),
    ));

void main() {
  late _Feed feed;
  late FakeAnalyticsClient analytics;
  late ProviderContainer container;
  late RiwayatAktivitasNotifier notifier;

  setUpAll(() => registerFallbackValue(const TransaksiFilter()));

  setUp(() {
    feed = _Feed();
    analytics = FakeAnalyticsClient();
    when(() => feed.execute(any())).thenAnswer((_) async => Right(AktivitasPage(
        [_setoran('1'), _setoran('2'), _setoran('3')], false,
        totalCount: 3)));
    container = ProviderContainer(overrides: [
      riwayatAktivitasProvider
          .overrideWith(() => RiwayatAktivitasNotifier(feed, _Export())),
      analyticsClientProvider.overrideWithValue(analytics),
    ]);
    addTearDown(container.dispose);
    notifier = container.read(riwayatAktivitasProvider.notifier);
  });

  List<String> names() => analytics.events.map((e) => e.name).toList();

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a one-character query is not a search', () async {
    notifier.search('b');
    await settle();

    expect(analytics.events, isEmpty);
  });

  test('searching starts a session and reports what it found', () async {
    notifier.search('nas');
    await settle();

    expect(names(), ['pencarian_dimulai', 'pencarian_hasil']);
    expect(analytics.events.last.properties, {
      'alur_id': analytics.events.first.properties['alur_id'],
      'area': 'riwayat',
      'jumlah_hasil_kelas': '1_5',
      'panjang_kueri_kelas': '3_5',
      'percobaan_ke': 1,
    });
    expect(analytics.events.toString(), isNot(contains('nas\'')));
  });

  test('a search no longer sends a filter change named pencarian', () async {
    notifier.search('nas');
    await settle();

    expect(names(), isNot(contains('riwayat_filter_diubah')));
  });

  test('changing the period under the same words is not another attempt',
      () async {
    notifier.search('nas');
    await settle();

    notifier.setPeriode('12_bulan');
    await settle();

    expect(names().where((n) => n == 'pencarian_hasil'), hasLength(1));
    expect(names().where((n) => n == 'riwayat_filter_diubah'), hasLength(1));
  });

  test('refining the words is another attempt', () async {
    notifier.search('nas');
    await settle();
    notifier.search('nasa');
    await settle();

    expect(analytics.events.last.properties['percobaan_ke'], 2);
  });

  test('opening a row of the results says where it was in the list', () async {
    notifier.search('nas');
    await settle();

    notifier.rowOpened(_setoran('2'));

    expect(names().last, 'pencarian_dipilih');
    expect(analytics.events.last.properties['posisi_hasil_kelas'], '2_3');
    expect(analytics.events.last.properties['percobaan_ke'], 1);
  });

  test('opening a row when nothing was searched sends nothing', () async {
    notifier.load();
    await settle();

    notifier.rowOpened(_setoran('2'));

    expect(analytics.events, isEmpty);
  });

  test('clearing the words after results means the search was given up',
      () async {
    notifier.search('nas');
    await settle();

    notifier.search('');
    await settle();

    expect(names(), contains('pencarian_ditinggalkan'));
    expect(
        analytics.events
            .firstWhere((e) => e.name == 'pencarian_ditinggalkan')
            .properties['hasil_terakhir_kelas'],
        '1_5');
  });

  test('leaving the report after a search is also giving up', () async {
    notifier.search('nas');
    await settle();

    notifier.reset();

    expect(names().last, 'pencarian_ditinggalkan');
  });

  test('resetting the filters ends the search too', () async {
    notifier.search('nas');
    await settle();

    notifier.resetFilters();
    await settle();

    expect(names(), contains('pencarian_ditinggalkan'));
  });
}
