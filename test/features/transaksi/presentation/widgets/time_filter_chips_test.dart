import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/time_filter_chips.dart';

import '../../../../support/platform_fakes.dart';
import '../../../../support/pump_app.dart';

class _MockGet extends Mock implements GetAktivitasUseCase {}

class _MockExport extends Mock implements ExportTransaksiUseCase {}

void main() {
  late _MockGet getTransaksi;
  late _MockExport export;
  late RiwayatAktivitasCubit cubit;

  setUpAll(() {
    registerFallbackValue(const TransaksiFilter());
  });

  setUp(() {
    getTransaksi = _MockGet();
    export = _MockExport();
    when(() => getTransaksi.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    cubit = RiwayatAktivitasCubit(getTransaksi, export);
  });

  tearDown(() => cubit.close());

  Future<void> open(WidgetTester tester,
      {Size size = const Size(800, 1600)}) async {
    await pumpRouted(
      tester,
      BlocProvider<RiwayatAktivitasCubit>.value(
        value: cubit,
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        child: Scaffold(body: TimeFilterChips()),
      ),
      size: size,
    );
  }

  /// A plain `MaterialApp` (no router): the export toasts push their own
  /// routes, which only coexist cleanly with an imperative navigator.
  Future<void> openPlain(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<RiwayatAktivitasCubit>.value(
        value: cubit,
        child: const Scaffold(body: TimeFilterChips()),
      ),
    ));
  }

  Future<void> selectPeriod(
      WidgetTester tester, String label, String period) async {
    final chip = find.text(label);
    expect(chip, findsOneWidget);
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(cubit.state.periode, period);
  }

  testWidgets('rolling one month sends its own period and resets custom dates',
      (tester) async {
    cubit.applyCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    await open(tester);
    await tester.pumpAndSettle();
    clearInteractions(getTransaksi);

    await selectPeriod(tester, '1 Bulan', '1_bulan');
    expect(cubit.state.dariTanggal, isNull);
    expect(cubit.state.sampaiTanggal, isNull);
    final filter = verify(() => getTransaksi.execute(captureAny()))
        .captured
        .single as TransaksiFilter;
    expect(filter.toQueryParams()['periode'], '1_bulan');

    await selectPeriod(tester, 'Bulan Ini', 'bulan_ini');
    await selectPeriod(tester, 'Bulan Lalu', 'bulan_lalu');
  });

  testWidgets('the chips switch between this month and last month',
      (tester) async {
    await open(tester);

    await selectPeriod(tester, 'Bulan Lalu', 'bulan_lalu');
    await selectPeriod(tester, 'Bulan Ini', 'bulan_ini');
  });

  testWidgets('the calendar button opens the range sheet and applies it',
      (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Pilih Rentang Waktu'), findsOneWidget);

    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    expect(cubit.state.periode, 'custom');
    expect(find.text('Pilih Rentang Waktu'), findsNothing);
    // The calendar button is highlighted once a custom range is active.
    final icon =
        tester.widget<Icon>(find.byIcon(Icons.calendar_today_outlined));
    expect(icon.color, Colors.white);
  });

  for (final size in [const Size(375, 844), const Size(320, 844)]) {
    testWidgets('calendar day targets stay 48dp at ${size.width}dp',
        (tester) async {
      await open(tester, size: size);
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      final today = DateUtils.dateOnly(DateTime.now());
      final dateKey = 'app-calendar-date-${today.year}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      final dateButton = find.byKey(ValueKey(dateKey));
      expect(tester.getSize(dateButton), const Size(48, 48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the range sheet can be closed without applying', (tester) async {
    await open(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(cubit.state.periode, 'bulan_ini');
    expect(find.text('Pilih Rentang Waktu'), findsNothing);
  });

  testWidgets('reopening the calendar preserves the selected custom range',
      (tester) async {
    cubit.applyCustomRange(DateTime(2025, 2, 3), DateTime(2025, 4, 15));
    await open(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('03/02/2025 – 15/04/2025'), findsOneWidget);
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();
    expect(cubit.state.dariTanggal, DateTime(2025, 2, 3));
    expect(cubit.state.sampaiTanggal, DateTime(2025, 4, 15));
  });

  testWidgets('the filter sheet normalizes a stored reversed range',
      (tester) async {
    cubit.applyCustomRange(DateTime(2026, 6, 30), DateTime(2026, 6, 1));
    await open(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();

    expect(find.text('01/06/2026 – 30/06/2026'), findsOneWidget);
  });

  testWidgets('the shared calendar applies a reversed range in order',
      (tester) async {
    cubit.applyCustomRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30));
    await open(tester);
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester
        .tap(find.byKey(const ValueKey('app-calendar-date-2026-06-20')));
    await tester
        .tap(find.byKey(const ValueKey('app-calendar-date-2026-06-10')));
    await tester.tap(find.text('Terapkan Filter'));
    await tester.pumpAndSettle();

    expect(cubit.state.dariTanggal, DateTime(2026, 6, 10));
    expect(cubit.state.sampaiTanggal, DateTime(2026, 6, 20));
  });

  testWidgets('export control reacts to type and search filters',
      (tester) async {
    await open(tester);
    FilledButton exportControl() => tester.widget<FilledButton>(find
        .ancestor(
            of: find.text('XLSX Laporan'), matching: find.byType(FilledButton))
        .first);
    expect(exportControl().onPressed, isNotNull);
    cubit.setTipeFilter(AktivitasTipeFilter.pencairan);
    await tester.pumpAndSettle();
    expect(exportControl().onPressed, isNotNull);
    cubit.setTipeFilter(AktivitasTipeFilter.semua);
    await tester.pumpAndSettle();
    expect(exportControl().onPressed, isNotNull);
    cubit.search('Budi');
    await tester.pumpAndSettle();
    expect(exportControl().onPressed, isNotNull);
    cubit.search('');
    await tester.pumpAndSettle();
    expect(exportControl().onPressed, isNotNull);
  });

  group('export', () {
    testWidgets('shows preparation while pending then reports an export error',
        (tester) async {
      final pending = Completer<Either<NetworkException, TransaksiExport>>();
      when(() => export.execute(any())).thenAnswer((_) => pending.future);
      await openPlain(tester);
      await tester.tap(find.text('XLSX Laporan'));
      await pumpToast(tester);
      expect(find.text('Menyiapkan laporan XLSX...'), findsOneWidget);
      expect(find.text('Bagikan'), findsNothing);
      pending
          .complete(Left(NetworkException(message: 'Akses laporan ditolak')));
      await pumpUntilFound(tester, find.text('Akses laporan ditolak'));
      expect(find.text('Menyiapkan laporan XLSX...'), findsNothing);
      expect(find.text('Akses laporan ditolak'), findsOneWidget);
      await settleToasts(tester);
    });

    // A real request takes a moment; the "preparing" toast must be on screen
    // before it is dismissed.
    void slowExport(Either<NetworkException, TransaksiExport> result) {
      when(() => export.execute(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        return result;
      });
    }

    testWidgets('saves the file, offers to share it', (tester) async {
      installFakePathProvider(downloads: 'Downloads');
      final share = installFakeSharePlatform();
      slowExport(Right(TransaksiExport(
          bytes: Uint8List.fromList([1, 2]), filename: 'r.xlsx')));
      await openPlain(tester);

      await tester.tap(find.text('XLSX Laporan'));
      await pumpUntilFound(
          tester, find.textContaining('disimpan ke folder Download'));

      expect(
          find.textContaining('Laporan berhasil disimpan ke folder Download'),
          findsOneWidget);

      // Let the toast finish sliding in before reaching for its button.
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Bagikan'));
      await pumpToast(tester);
      expect(share.shared.single.text, 'Laporan Transaksi PILAH');
      await settleToasts(tester);
    });

    testWidgets('shows the failure message', (tester) async {
      slowExport(Left(NetworkException(message: 'Tidak ada data')));
      await openPlain(tester);

      await tester.tap(find.text('XLSX Laporan'));
      await pumpUntilFound(tester, find.text('Tidak ada data'));

      expect(find.text('Tidak ada data'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('reports a file that could not be saved', (tester) async {
      final paths = installFakePathProvider();
      File(paths.documents).createSync(recursive: true);
      slowExport(Right(
          TransaksiExport(bytes: Uint8List.fromList([1]), filename: 'r.xlsx')));
      await openPlain(tester);

      await tester.tap(find.text('XLSX Laporan'));
      await pumpUntilFound(tester, find.text('Gagal Menyimpan'));

      expect(find.text('Gagal Menyimpan'), findsOneWidget);
      await settleToasts(tester);
    });
  });
}
