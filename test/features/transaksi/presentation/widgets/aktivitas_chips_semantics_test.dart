import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_tipe_chips.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/time_filter_chips.dart';

class _MockGet extends Mock implements GetTransaksiUseCase {}

class _MockPencairan extends Mock implements PencairanUseCases {}

class _MockExport extends Mock implements ExportTransaksiUseCase {}

void main() {
  late RiwayatAktivitasCubit cubit;

  setUpAll(() {
    registerFallbackValue(const TransaksiFilter());
    registerFallbackValue(const RiwayatPencairanFilter());
  });

  setUp(() {
    final get = _MockGet();
    final pencairan = _MockPencairan();
    when(() => get.execute(any())).thenAnswer((_) async => const Right([]));
    when(() => pencairan.getRiwayat(any()))
        .thenAnswer((_) async => const Right([]));
    cubit = RiwayatAktivitasCubit(get, pencairan, _MockExport());
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
