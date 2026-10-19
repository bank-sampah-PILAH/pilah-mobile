import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_filter_bar.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/periode_picker_sheet.dart';

class _Feed extends Mock implements GetAktivitasUseCase {}

class _Export extends Mock implements ExportTransaksiUseCase {}

void main() {
  late RiwayatAktivitasCubit cubit;

  setUpAll(() => registerFallbackValue(const TransaksiFilter()));

  setUp(() {
    final feed = _Feed();
    when(() => feed.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    cubit = RiwayatAktivitasCubit(feed, _Export());
  });

  tearDown(() => cubit.close());

  Future<void> pumpBar(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: AktivitasFilterBar(),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('wide: type segments, period button and labeled export',
      (tester) async {
    await pumpBar(tester, width: 1200);

    for (final label in ['Semua', 'Setoran', 'Pencairan', 'Bulan Ini']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Ekspor XLSX'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
    expect(find.text('12 Bulan'), findsNothing);
  });

  testWidgets('phone: export is an icon button with a tooltip', (tester) async {
    await pumpBar(tester, width: 360);

    expect(find.byTooltip('Ekspor XLSX'), findsOneWidget);
    expect(find.text('Ekspor XLSX'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing a type segment filters the feed', (tester) async {
    await pumpBar(tester, width: 1200);

    await tester.tap(find.text('Pencairan'));
    await tester.pump();

    expect(cubit.state.tipeFilter, AktivitasTipeFilter.pencairan);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('the period picker lists every preset and applies the choice',
      (tester) async {
    await pumpBar(tester, width: 1200);

    await tester.tap(find.text('Bulan Ini'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Periode'), findsOneWidget);
    for (final (_, label) in periodePresets) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Rentang tanggal…'), findsOneWidget);

    await tester.tap(find.text('Semua Waktu'));
    await tester.pumpAndSettle();

    expect(cubit.state.periode, 'semua');
    expect(find.text('Pilih Periode'), findsNothing);
    expect(find.text('Semua Waktu'), findsOneWidget);
  });

  testWidgets('a custom range shows its dates on the button', (tester) async {
    cubit.applyCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    await pumpBar(tester, width: 1200);

    expect(find.text('01/09/2026 – 30/09/2026'), findsOneWidget);
  });

  testWidgets('"Rentang tanggal…" hands over to the date range sheet',
      (tester) async {
    await pumpBar(tester, width: 1200);

    await tester.tap(find.text('Bulan Ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rentang tanggal…'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Periode'), findsNothing);
    expect(find.text('Terapkan Filter'), findsOneWidget);
  });

  testWidgets('phone: the reset icon restores the defaults and disappears',
      (tester) async {
    await pumpBar(tester, width: 360);
    cubit.setPeriode('12_bulan');
    await tester.pumpAndSettle();
    expect(find.text('12 Bulan'), findsOneWidget);

    await tester.tap(find.byTooltip('Reset filter'));
    await tester.pumpAndSettle();

    expect(cubit.state.periode, 'bulan_ini');
    expect(find.byTooltip('Reset filter'), findsNothing);
    expect(find.text('Bulan Ini'), findsOneWidget);
  });
}
