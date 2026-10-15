import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/revisi_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/revisi_pencairan_page.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

final _riwayat = RiwayatRevisiPencairan(
  pencairan: Pencairan(
    id: 'p-1',
    nasabahNama: 'Ahmad Ridwan',
    nominal: 150000,
    metode: MetodePencairan.transfer,
    tanggal: DateTime(2026, 9, 21, 9, 30),
    keterangan: 'Ditransfer',
    status: 'tercatat',
    saldoSebelum: 465600,
    saldoSesudah: 315600,
    diperbarui: true,
  ),
  revisi: [
    RevisiPencairan(
      versi: 2,
      tanggal: DateTime(2026, 9, 21, 9, 30),
      nominal: 200000,
      metode: MetodePencairan.transfer,
      keterangan: 'Ditransfer',
      saldoSebelum: 465600,
      saldoSesudah: 265600,
      alasan: 'Salah ketik nominal',
      diubahOlehNama: 'Ibu Sari',
      diubahPada: DateTime(2026, 9, 22, 11, 5),
    ),
    RevisiPencairan(
      versi: 1,
      tanggal: DateTime(2026, 9, 21, 9, 30),
      nominal: 200000,
      metode: MetodePencairan.tunai,
      keterangan: 'Diambil pagi',
      saldoSebelum: 465600,
      saldoSesudah: 265600,
      alasan: 'Salah pilih metode',
      diubahOlehNama: 'Pak Budi',
      diubahPada: DateTime(2026, 9, 22, 10, 0),
    ),
  ],
);

void main() {
  late _MockUseCases useCases;

  setUp(() => useCases = _MockUseCases());

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RevisiPencairanCubit(useCases),
          child: const RevisiPencairanView(pencairanId: 'p-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the current version, then replaced versions with why',
      (tester) async {
    when(() => useCases.getRevisi('p-1'))
        .thenAnswer((_) async => Right(_riwayat));
    await pumpView(tester);

    expect(find.text('Versi sekarang'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('Versi 2'), findsOneWidget);
    expect(find.text('Versi 1'), findsOneWidget);
    expect(find.text('Salah ketik nominal'), findsOneWidget);
    expect(find.text('Salah pilih metode'), findsOneWidget);
    expect(find.text('Diubah oleh Ibu Sari · 22 September 2026, 11:05'),
        findsOneWidget);
    expect(find.text('Rp 200.000'), findsNWidgets(2));
  });

  testWidgets('offers a retry when the history cannot be loaded',
      (tester) async {
    when(() => useCases.getRevisi('p-1')).thenAnswer(
      (_) async => Left(NotFoundException(message: 'Resource tidak ditemukan')),
    );
    await pumpView(tester);

    expect(find.text('Resource tidak ditemukan'), findsOneWidget);
    when(() => useCases.getRevisi('p-1'))
        .thenAnswer((_) async => Right(_riwayat));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Versi 2'), findsOneWidget);
  });
}
