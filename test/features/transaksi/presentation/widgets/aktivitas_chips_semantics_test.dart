import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_tipe_chips.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/time_filter_chips.dart';

class _MockGet extends Mock implements GetAktivitasUseCase {}

class _MockExport extends Mock implements ExportTransaksiUseCase {}

void main() {
  late RiwayatAktivitasCubit cubit;

  setUpAll(() {
    registerFallbackValue(const TransaksiFilter());
  });

  setUp(() {
    final get = _MockGet();
    when(() => get.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    cubit = RiwayatAktivitasCubit(get, _MockExport());
  });

  tearDown(() => cubit.close());

  Finder chip(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(AppChip),
      );

  testWidgets('the type and period chips announce which one is selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<RiwayatAktivitasCubit>.value(
        value: cubit,
        child: const Scaffold(
          body: Column(children: [AktivitasTipeChips(), TimeFilterChips()]),
        ),
      ),
    ));

    expect(
      tester.getSemantics(chip('Semua')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    expect(
      tester.getSemantics(chip('Setoran')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );
    expect(
      tester.getSemantics(chip('Bulan Ini')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    expect(
      tester.getSemantics(chip('Bulan Lalu')),
      isSemantics(hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });
}
