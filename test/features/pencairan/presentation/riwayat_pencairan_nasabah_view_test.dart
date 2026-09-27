import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_nasabah_page.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

Pencairan _row() => Pencairan(
      id: 'p-1',
      nasabahId: 'n-1',
      nasabahNama: 'Ayu Nasabah',
      bankSampahNama: 'Bank Sampah Kenanga',
      nominal: 150000,
      metode: MetodePencairan.transfer,
      tanggal: DateTime(2026, 9, 27, 9, 5),
      keterangan: 'Keterangan terbaru',
      status: 'tercatat',
      saldoSebelum: 200000,
      saldoSesudah: 50000,
      diperbarui: true,
    );

void main() {
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));

  late _MockUseCases useCases;

  setUp(() {
    useCases = _MockUseCases();
    when(() => useCases.getRiwayat(any()))
        .thenAnswer((_) async => Right([_row()]));
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RiwayatPencairanCubit(useCases),
          child: const RiwayatPencairanNasabahView(),
        ),
      ),
    );
  }

  testWidgets('shows current payout values and bank without revision actions',
      (tester) async {
    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bank Sampah Kenanga'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.text('27 September 2026'), findsOneWidget);
    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('Keterangan terbaru'), findsOneWidget);
    expect(find.text('Diperbarui'), findsOneWidget);
    expect(find.text('Edit Pencairan'), findsNothing);
    expect(find.text('Riwayat Perubahan'), findsNothing);
    expect(find.text('Salah catat'), findsNothing);
  });

  testWidgets('shows a loading indicator while history is being fetched',
      (tester) async {
    final result = Completer<Either<NetworkException, List<Pencairan>>>();
    when(() => useCases.getRiwayat(any())).thenAnswer((_) => result.future);

    await pumpView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    result.complete(Right([_row()]));
    await tester.pumpAndSettle();
    expect(find.text('Bank Sampah Kenanga'), findsOneWidget);
  });

  testWidgets('shows an empty state when the Nasabah has no payouts',
      (tester) async {
    when(() => useCases.getRiwayat(any())).thenAnswer((_) async => Right([]));

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada riwayat pencairan'), findsOneWidget);
  });

  testWidgets('allows retry after a history request fails', (tester) async {
    var attempts = 0;
    when(() => useCases.getRiwayat(any())).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) {
        return Left(NetworkException(message: 'Layanan tidak tersedia'));
      }
      return Right([_row()]);
    });

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Layanan tidak tersedia'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Bank Sampah Kenanga'), findsOneWidget);
  });

  testWidgets('allows pull-to-refresh', (tester) async {
    await pumpView(tester);
    await tester.pumpAndSettle();

    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await tester.pumpAndSettle();

    verify(() => useCases.getRiwayat(any())).called(2);
  });
}
