import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';

import '../../../../support/fake_analytics_client.dart';

class _Feed extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

ActivitasEntity _setoran() => ActivitasEntity.fromTransaksi(TransaksiEntity(
      id: '1',
      initials: 'BU',
      avatarColor: Colors.green.shade100,
      textColor: Colors.green,
      name: 'Nasabah 1',
      subtitle: 'Botol PET • 2 kg',
      amount: '+Rp 4.000',
      isWaSuccess: false,
      time: '10:00',
      balance: '',
      items: const [],
      tanggal: DateTime(2026, 10, 5, 10),
    ));

void main() {
  setUpAll(() => registerFallbackValue(const TransaksiFilter()));

  testWidgets(
      'leaving the report closes the search, and coming back starts a new one',
      (tester) async {
    final feed = _Feed();
    when(() => feed.execute(any())).thenAnswer(
        (_) async => Right(AktivitasPage([_setoran()], false, totalCount: 1)));
    final analytics = FakeAnalyticsClient();
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    late ProviderContainer container;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riwayatAktivitasProvider
            .overrideWith(() => RiwayatAktivitasNotifier(feed, _Export())),
        analyticsClientProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          // The shell keeps the report of a tab that is not shown, with its
          // tickers off.
          builder: (_, shown, __) => TickerMode(
            enabled: shown,
            child: Consumer(builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const LaporanPage();
            }),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    List<String> names() => analytics.events.map((e) => e.name).toList();

    container.read(riwayatAktivitasProvider.notifier).search('bu');
    await tester.pumpAndSettle();
    expect(names(), ['pencarian_dimulai', 'pencarian_hasil']);
    final firstFlow = analytics.events.first.properties['alur_id'];

    visible.value = false;
    await tester.pump();
    expect(names().last, 'pencarian_ditinggalkan');

    visible.value = true;
    await tester.pump();
    container.read(riwayatAktivitasProvider.notifier).search('bud');
    await tester.pumpAndSettle();

    final second =
        analytics.events.lastWhere((e) => e.name == 'pencarian_hasil');
    expect(second.properties['percobaan_ke'], 1);
    expect(second.properties['alur_id'], isNot(firstFlow));
  });
}
