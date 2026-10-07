import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_state.dart';

class Feed extends Mock implements GetAktivitasUseCase {}

class Export extends Mock implements ExportTransaksiUseCase {}

void main() {
  setUpAll(() => registerFallbackValue(const TransaksiFilter()));
  test('export retains the current period and reset clears all filters',
      () async {
    final feed = Feed();
    final export = Export();
    final cubit = RiwayatAktivitasCubit(feed, export);
    addTearDown(cubit.close);
    when(() => feed.execute(any()))
        .thenAnswer((_) async => const Right(AktivitasPage([], false)));
    final expected =
        TransaksiExport(bytes: Uint8List.fromList([1]), filename: 'test.xlsx');
    when(() => export.execute(any())).thenAnswer((_) async => Right(expected));
    cubit.applyCustomRange(DateTime(2026, 9, 1), DateTime(2026, 9, 30));
    await Future<void>.delayed(Duration.zero);
    expect((await cubit.exportTransaksi()).export, expected);
    final filter = verify(() => export.execute(captureAny())).captured.single
        as TransaksiFilter;
    expect(filter.periode, 'custom');
    expect(filter.dariTanggal, DateTime(2026, 9, 1));
    cubit.reset();
    expect(cubit.state, const RiwayatAktivitasState());
  });
}
