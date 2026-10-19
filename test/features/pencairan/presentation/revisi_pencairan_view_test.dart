import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
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

  testWidgets('lists the current version, then each change with why',
      (tester) async {
    when(() => useCases.getRevisi('p-1'))
        .thenAnswer((_) async => Right(_riwayat));
    await pumpView(tester);

    expect(find.text('VERSI SEKARANG'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('PERUBAHAN (2)'), findsOneWidget);
    expect(find.text('Mengganti versi 2'), findsOneWidget);
    expect(find.text('Mengganti versi 1'), findsOneWidget);
    expect(find.text('Salah ketik nominal'), findsOneWidget);
    expect(find.text('Salah pilih metode'), findsOneWidget);
    expect(find.text('Diubah oleh Ibu Sari · 22 September 2026, 11:05'),
        findsOneWidget);
  });

  testWidgets('keeps the versions to a readable column on a desktop window',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => useCases.getRevisi('p-1'))
        .thenAnswer((_) async => Right(_riwayat));
    await pumpView(tester);

    final list = find.ancestor(
      of: find.text('VERSI SEKARANG'),
      matching: find.byType(ListView),
    );
    expect(tester.getSize(list).width,
        lessThanOrEqualTo(LayoutBreakpoint.formMaxWidth));
    expect(tester.getCenter(list).dx, closeTo(720, 1),
        reason: 'centred in the window');
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

    expect(find.text('Mengganti versi 2'), findsOneWidget);
  });

  group('looks like the rest of the app', () {
    testWidgets('has a white page headed by the back button, not an app bar',
        (tester) async {
      when(() => useCases.getRevisi('p-1'))
          .thenAnswer((_) async => Right(_riwayat));
      await pumpView(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.widgetWithText(AppBackHeader, 'Riwayat Perubahan'),
          findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.white,
      );
    });

    testWidgets('keeps the header when the history cannot be loaded',
        (tester) async {
      when(() => useCases.getRevisi('p-1')).thenAnswer(
        (_) async => Left(NotFoundException(message: 'Tidak ditemukan')),
      );
      await pumpView(tester);

      expect(find.widgetWithText(AppBackHeader, 'Riwayat Perubahan'),
          findsOneWidget);
    });

    testWidgets('shows only what each change altered, old value to new',
        (tester) async {
      when(() => useCases.getRevisi('p-1'))
          .thenAnswer((_) async => Right(_riwayat));
      await pumpView(tester);

      expect(
          find.textContaining('Rp 200.000  →  Rp 150.000', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('Tunai  →  Transfer', findRichText: true),
          findsOneWidget);
      expect(
          find.textContaining('Diambil pagi  →  Ditransfer',
              findRichText: true),
          findsOneWidget);
      // Nominal did not change from version 1 to 2, so it is not listed there.
      expect(find.text('Nominal'), findsOneWidget);
    });

    testWidgets('a change that altered no value says so', (tester) async {
      final same = RiwayatRevisiPencairan(
        pencairan: _riwayat.pencairan,
        revisi: [
          RevisiPencairan(
            versi: 1,
            tanggal: _riwayat.pencairan.tanggal,
            nominal: _riwayat.pencairan.nominal,
            metode: _riwayat.pencairan.metode,
            keterangan: _riwayat.pencairan.keterangan,
            saldoSebelum: 465600,
            saldoSesudah: 315600,
            alasan: 'Cek ulang',
            diubahOlehNama: 'Ibu Sari',
            diubahPada: DateTime(2026, 9, 22, 11, 5),
          ),
        ],
      );
      when(() => useCases.getRevisi('p-1'))
          .thenAnswer((_) async => Right(same));
      await pumpView(tester);

      expect(find.text('Tidak ada nilai yang berubah.'), findsOneWidget);
    });
  });
}
