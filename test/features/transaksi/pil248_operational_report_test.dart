import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/aktivitas_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_summary.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/laporan/laporan_page.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_summary_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../support/notifier_harness.dart';

class _Network extends Mock implements NetworkService {}

class _Feed extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

const _totals = <String, dynamic>{
  'jumlah_transaksi': 25,
  'total_berat': '12.50',
  'total_setoran': 150000,
  'total_pencairan': 200000,
  'saldo': -50000,
};
const _zero = <String, dynamic>{
  'jumlah_transaksi': 0,
  'total_berat': '0.00',
  'total_setoran': 0,
  'total_pencairan': 0,
  'saldo': 0,
};

Future<Either<NetworkException, AktivitasPage>> _response(Object? summary,
    {bool next = false}) async {
  final network = _Network();
  when(() => network.get('/api/v1/aktivitas',
      queryParams: any(named: 'queryParams'))).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/aktivitas'),
          data: {
            'results': [],
            'next': next ? '/page/2' : null,
            'summary': summary
          }));
  return AktivitasRepositoryImpl(network).history(const TransaksiFilter());
}

Future<AktivitasPage> _page(Map<String, dynamic> totals,
    {bool next = false}) async {
  final result = await _response(totals, next: next);
  return result.fold((error) => throw error, (page) => page);
}

void main() {
  setUpAll(() async {
    registerFallbackValue(const TransaksiFilter());
    // Layout budgets must use the shipped font, not the square Ahem test font.
    for (final (style, asset) in [
      (AppTextStyle.small, 'assets/fonts/PoppinsRegular.ttf'),
      (AppTextStyle.headline3, 'assets/fonts/PoppinsMedium.ttf'),
    ]) {
      final loader = FontLoader(style.fontFamily!)
        ..addFont(rootBundle.load(asset));
      await loader.load();
    }
  });

  test(
      'positive: parses whole filtered summary, including negative period balance',
      () async {
    final page = await _page(_totals);
    expect(page.summary!.jumlahTransaksi, 25);
    expect(page.summary!.totalBerat, 12.5);
    expect(page.summary!.totalSetoran, 150000);
    expect(page.summary!.totalPencairan, 200000);
    expect(page.summary!.saldo, -50000);
  });

  test('corner: empty results preserve genuine zero summary', () async {
    final page = await _page(_zero);
    expect(page.items, isEmpty);
    expect(page.summary!.jumlahTransaksi, 0);
    expect(page.summary!.saldo, 0);
  });

  test('summary value equality keeps state comparisons deterministic',
      () async {
    final summary = (await _page(_totals)).summary!;
    const equivalent = AktivitasSummary(
        jumlahTransaksi: 25,
        totalBerat: 12.5,
        totalSetoran: 150000,
        totalPencairan: 200000,
        saldo: -50000);
    expect(summary, equivalent);
    expect(summary.hashCode, equivalent.hashCode);
    final state = RiwayatAktivitasState(summary: summary, periode: 'custom');
    expect(state.isCustomPeriode, isTrue);
    expect(state.copyWith(search: 'Ani').summary, summary);
    expect(state.copyWith(clearSummary: true).summary, isNull);
    expect(state.copyWith(summary: (await _page(_zero)).summary), isNot(state));
  });

  for (final bad in [
    null,
    'invalid',
    {..._totals}..remove('saldo'),
    {..._totals, 'jumlah_transaksi': -1},
    {..._totals, 'jumlah_transaksi': 1.5},
    {..._totals, 'jumlah_transaksi': true},
    {..._totals, 'total_setoran': '150000'},
    {..._totals, 'total_setoran': -1},
    {..._totals, 'total_pencairan': -1},
    {..._totals, 'total_pencairan': 0.5},
    {..._totals, 'total_berat': 'NaN'},
    {..._totals, 'total_berat': 'Infinity'},
    {..._totals, 'total_berat': 12.5},
    {..._totals, 'total_berat': '-1.00'},
    {..._totals, 'saldo': 42},
    {..._totals, 'saldo': '-50000'},
  ]) {
    test('negative: malformed summary fails closed: $bad', () async {
      expect((await _response(bad)).isLeft(), isTrue);
    });
  }

  test(
      'positive: export keeps custom dates, withdrawal type and trimmed search',
      () async {
    final feed = _Feed();
    final export = _Export();
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, export),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    when(() => export.execute(any())).thenAnswer((_) async => Right(
        TransaksiExport(
            bytes: Uint8List.fromList([1]), filename: 'laporan.xlsx')));
    cubit.applyCustomRange(DateTime(2026, 10, 1), DateTime(2026, 10, 14));
    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);
    cubit.search('  Ani  ');
    await pumpEventQueue();
    expect((await cubit.exportTransaksi()).export?.filename, 'laporan.xlsx');
    final filter = verify(() => export.execute(captureAny())).captured.single
        as TransaksiFilter;
    expect(filter.toQueryParams(), {
      'periode': 'custom',
      'dari_tanggal': '2026-10-01',
      'sampai_tanggal': '2026-10-14',
      'tipe': 'pencairan',
      'search': 'Ani',
    });
  });

  test('negative: export failure returns error without a file', () async {
    final export = _Export();
    when(() => export.execute(any())).thenAnswer(
        (_) async => Left(NetworkException(message: 'Tidak diizinkan')));
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(_Feed(), export),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    final result = await cubit.exportTransaksi();
    expect(result.export, isNull);
    expect(result.error, 'Tidak diizinkan');
  });

  test(
      'edge: refresh clears stale totals, rejects old request and resets on logout',
      () async {
    final feed = _Feed();
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_totals)));
    await cubit.load();
    final loaded = cubit.state;
    expect(loaded.summary!.saldo, -50000);
    final old = Completer<Either<NetworkException, AktivitasPage>>();
    when(() => feed.execute(any())).thenAnswer((_) => old.future);
    final pending = cubit.load(silent: true);
    final loading = cubit.state;
    expect(loading.summary, isNull);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    await cubit.load();
    old.complete(Right(await _page(_totals)));
    await pending;
    final latest = cubit.state;
    expect(latest.summary!.saldo, 0);
    cubit.reset();
    final reset = cubit.state;
    expect(reset.summary, isNull);
  });

  test('edge: pagination keeps whole-filter summary without summing pages',
      () async {
    final feed = _Feed();
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    when(() => feed.execute(any())).thenAnswer((invocation) async {
      final filter = invocation.positionalArguments.first as TransaksiFilter;
      return Right(await _page(filter.page == 1 ? _totals : _zero,
          next: filter.page == 1));
    });
    await cubit.load();
    final summary = cubit.state.summary;
    await cubit.loadMore();
    expect(cubit.state.summary, summary);
    expect(cubit.state.hasNext, isFalse);
    verify(() => feed.execute(any())).called(2);
  });

  test('negative: refresh failure clears totals; retry restores zero summary',
      () async {
    final feed = _Feed();
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_totals)));
    await cubit.load();
    when(() => feed.execute(any())).thenAnswer(
        (_) async => Left(NetworkException(message: 'Tidak diizinkan')));
    await cubit.load(silent: true);
    expect(cubit.state.summary, isNull);
    expect(cubit.state.status, AktivitasStatus.failure);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    await cubit.load();
    expect(cubit.state.summary?.jumlahTransaksi, 0);
  });

  testWidgets(
      'loading, empty and failure display explicit states without stale totals',
      (tester) async {
    final feed = _Feed();
    final pending = Completer<Either<NetworkException, AktivitasPage>>();
    when(() => feed.execute(any())).thenAnswer((_) => pending.future);
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    // Phone: the summary card sits in the page header; wide windows show it as
    // a strip inside the table card instead.
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: UncontrolledProviderScope(
      container: harness.container,
      child: const LaporanPage(),
    )));
    await tester.pump();
    expect(find.bySemanticsLabel('Memuat ringkasan laporan'), findsOneWidget);
    expect(find.text('Saldo Periode'), findsNothing);
    pending.complete(Right(await _page(_zero)));
    await tester.pumpAndSettle();
    // A period without activity hides the strip of zeros.
    expect(find.text('Saldo Periode'), findsNothing);
    expect(find.text('Rp 0'), findsNothing);
    expect(find.text('Belum Ada Aktivitas'), findsOneWidget);
    when(() => feed.execute(any())).thenAnswer(
        (_) async => Left(NetworkException(message: 'Gagal memuat')));
    await cubit.load();
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan gagal dimuat. Silakan coba lagi.'),
        findsOneWidget);
    expect(find.text('Rp 0'), findsNothing);
    expect(find.text('Coba Lagi'), findsOneWidget);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(
        find.text('Ringkasan gagal dimuat. Silakan coba lagi.'), findsNothing);
  });

  testWidgets(
      'positive and narrow edge: phone summary shows setoran, pencairan and saldo without scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final feed = _Feed();
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_totals)));
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(MaterialApp(
        home: UncontrolledProviderScope(
      container: harness.container,
      child: const LaporanPage(),
    )));
    await tester.pumpAndSettle();
    for (final label in [
      'Total Nilai Setoran',
      'Total Pencairan',
      'Saldo Periode'
    ]) {
      expect(find.text(label), findsOneWidget);
      expect(tester.getRect(find.text(label)).right, lessThanOrEqualTo(360));
    }
    expect(find.text('25 transaksi · 12,5 kg'), findsOneWidget);
    expect(find.text('-Rp 50.000'), findsOneWidget);
    expect(find.byTooltip('Ekspor XLSX'), findsOneWidget);
    expect(tester.getSize(find.byType(AktivitasSummaryView)).height,
        lessThanOrEqualTo(200),
        reason: 'The summary must leave more room for transaction history.');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Saldo Periode'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Saldo Periode'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(
        find.text(
            'Selisih total setoran dan pencairan pada periode dan filter yang dipilih.'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  for (final (width, scale) in [(320.0, 1.0), (360.0, 2.0), (1440.0, 1.0)]) {
    testWidgets(
        'full summary values remain readable at width $width, scale $scale',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final feed = _Feed();
      when(() => feed.execute(any()))
          .thenAnswer((_) async => Right(await _page({
                'jumlah_transaksi': 12345678,
                'total_berat': '1234567.89',
                'total_setoran': 2000000000000,
                'total_pencairan': 3000000000000,
                'saldo': -1000000000000,
              })));
      final harness = NotifierHarness(
        riwayatAktivitasProvider,
        () => RiwayatAktivitasNotifier(feed, _Export()),
      );
      final cubit = harness.notifier;
      addTearDown(harness.dispose);
      await cubit.load();
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: UncontrolledProviderScope(
                          container: harness.container,
                          child: const AktivitasSummaryView()))))));
      await tester.pumpAndSettle();
      final wide = width >= 720;
      for (final text in [
        if (wide) ...['Total Transaksi', 'Total Berat Sampah', '12345678'],
        if (wide) '1234567,89 kg' else '12345678 transaksi · 1234567,89 kg',
        'Total Nilai Setoran',
        'Total Pencairan',
        'Saldo Periode',
        'Rp 2.000.000.000.000',
        'Rp 3.000.000.000.000',
        '-Rp 1.000.000.000.000'
      ]) {
        expect(find.text(text), findsOneWidget);
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        final bounds = tester.getRect(find.text(text));
        expect(bounds.left, greaterThanOrEqualTo(16));
        expect(bounds.right, lessThanOrEqualTo(width - 16));
      }
      expect(find.text('Saldo Akhir Periode'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the strip shows every total on one line, with the saldo marked',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final feed = _Feed();
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_totals)));
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    await cubit.load();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: UncontrolledProviderScope(
                container: harness.container,
                child: const AktivitasSummaryStrip()))));
    await tester.pumpAndSettle();

    expect(
        tester.getSize(find.byType(AktivitasSummaryStrip)).height, lessThan(60),
        reason: 'one line, not a card');
    final text = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .join('|');
    for (final part in [
      '25',
      '12,5 kg',
      'Rp 150.000',
      'Rp 200.000',
      '-Rp 50.000'
    ]) {
      expect(text, contains(part));
    }
  });

  testWidgets('the strip hides itself while loading and for an empty period',
      (tester) async {
    final feed = _Feed();
    when(() => feed.execute(any()))
        .thenAnswer((_) async => Right(await _page(_zero)));
    final harness = NotifierHarness(
      riwayatAktivitasProvider,
      () => RiwayatAktivitasNotifier(feed, _Export()),
    );
    final cubit = harness.notifier;
    addTearDown(harness.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: UncontrolledProviderScope(
                container: harness.container,
                child: const AktivitasSummaryStrip()))));
    expect(tester.getSize(find.byType(AktivitasSummaryStrip)).height, 0);
    await cubit.load();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AktivitasSummaryStrip)).height, 0);
  });
}
