import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_summary.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_filter_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_summary_view.dart';
import '../../../support/notifier_harness.dart';

class _Feed extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

const _setoranSaja = AktivitasSummary(
  jumlahTransaksi: 25,
  totalBerat: 12.5,
  totalSetoran: 150000,
  totalPencairan: 0,
  saldo: 150000,
);

/// PIL-435 (CPBI-31): Pencairan is closed for now, so Riwayat offers only
/// setoran: no Semua or Pencairan type, and no pencairan totals.
void main() {
  late _Feed feed;
  late NotifierHarness<RiwayatAktivitasNotifier, RiwayatAktivitasState> harness;

  setUpAll(() => registerFallbackValue(const TransaksiFilter()));

  setUp(() {
    feed = _Feed();
    when(() => feed.execute(any())).thenAnswer((_) async =>
        const Right(AktivitasPage([], false, summary: _setoranSaja)));
    harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
  });

  tearDown(() => harness.dispose());

  void useWidth(WidgetTester tester, double width) {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      home: UncontrolledProviderScope(
        container: harness.container,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  test('Riwayat opens on setoran and asks the server for setoran only',
      () async {
    final notifier = harness.notifier;
    expect(notifier.state.tipeFilter, AktivitasTipeFilter.setoran);

    await notifier.load();

    final filter = verify(() => feed.execute(captureAny())).captured.single
        as TransaksiFilter;
    expect(filter.tipe, 'setoran');
  });

  test('Reset returns to setoran, not to Semua', () async {
    final notifier = harness.notifier;
    notifier.setPeriode('12_bulan');
    notifier.search('Budi');
    await pumpEventQueue();

    notifier.resetFilters();
    await pumpEventQueue();

    expect(notifier.state.tipeFilter, AktivitasTipeFilter.setoran);
    expect(notifier.state.periode, 'bulan_ini');
    expect(notifier.state.search, isEmpty);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('at ${width.toInt()}px there is no type selector to tap',
        (tester) async {
      useWidth(tester, width);
      await pump(tester, const AktivitasFilterBar());

      expect(find.byType(SegmentedButton<AktivitasTipeFilter>), findsNothing);
      for (final label in ['Semua', 'Setoran', 'Pencairan']) {
        expect(find.text(label), findsNothing);
      }
      // The rest of the bar is untouched, and nothing invites a Reset.
      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
      expect(find.byTooltip('Reset filter'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [1440.0, 360.0]) {
    testWidgets(
        'at ${width.toInt()}px the setoran summary has no pencairan or saldo',
        (tester) async {
      useWidth(tester, width);
      harness.notifier.setTipeFilter(AktivitasTipeFilter.setoran);
      await harness.notifier.load();
      await pump(tester, const AktivitasSummaryView());

      expect(find.text('Total Nilai Setoran'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsOneWidget);
      expect(find.text('Total Pencairan'), findsNothing);
      expect(find.text('Saldo Periode'), findsNothing);
      expect(find.text('Rp 0'), findsNothing);
      if (width >= 720) {
        expect(find.text('Total Transaksi'), findsOneWidget);
        expect(find.text('12,5 kg'), findsOneWidget);
      } else {
        expect(find.text('25 transaksi · 12,5 kg'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the setoran strip has no pencairan or saldo', (tester) async {
    useWidth(tester, 1200);
    harness.notifier.setTipeFilter(AktivitasTipeFilter.setoran);
    await harness.notifier.load();
    await pump(tester, const AktivitasSummaryStrip());

    final text = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .join('|');
    expect(text, contains('Rp 150.000'));
    expect(text, contains('12,5 kg'));
    expect(text, isNot(contains('Pencairan')));
    expect(text, isNot(contains('Saldo')));
  });
}
