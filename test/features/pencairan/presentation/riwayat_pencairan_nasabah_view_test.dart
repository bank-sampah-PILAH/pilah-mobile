import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_history_tab.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

Pencairan _row({
  String id = 'p-1',
  String bankSampahNama = 'Bank Sampah Kenanga',
}) =>
    Pencairan(
      id: id,
      nasabahId: 'n-1',
      nasabahNama: 'Ayu Nasabah',
      bankSampahNama: bankSampahNama,
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

  setUp(() async {
    if (di.isRegistered<RiwayatPencairanCubit>()) {
      await di.unregister<RiwayatPencairanCubit>();
    }
    useCases = _MockUseCases();
    when(() => useCases.getRiwayat(any()))
        .thenAnswer((_) async => Right([_row()]));
    di.registerFactory<RiwayatPencairanCubit>(
      () => RiwayatPencairanCubit(useCases),
    );
  });
  tearDown(() => di.unregister<RiwayatPencairanCubit>());

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PencairanHistoryTab())),
    );
  }

  testWidgets('shows payouts in the same activity card style as setoran',
      (tester) async {
    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.text('− Rp 150.000'), findsOneWidget);
    expect(find.text('27/09/2026 · 09.05'), findsOneWidget);
    expect(find.text('Transfer'), findsNothing);
    expect(find.text('Keterangan terbaru'), findsNothing);
    expect(find.text('Riwayat Pencairan'), findsOneWidget);
    expect(find.text('Edit Pencairan'), findsNothing);
  });

  testWidgets('tapping a payout opens a read-only detail sheet',
      (tester) async {
    await pumpView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pencairan'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);
    expect(find.textContaining('27 September 2026'), findsOneWidget);
    expect(find.text('Keterangan terbaru'), findsOneWidget);
    expect(find.text('Saldo sebelum'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsOneWidget);
    expect(find.text('Edit Pencairan'), findsNothing);
    expect(find.text('Riwayat Perubahan'), findsNothing);
  });

  testWidgets('renders multiple payouts in the history list', (tester) async {
    when(() => useCases.getRiwayat(any())).thenAnswer(
      (_) async => Right([
        _row(),
        _row(id: 'p-2', bankSampahNama: 'Bank Sampah BTH'),
      ]),
    );

    await pumpView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Pencairan'), findsNWidgets(2));
    expect(find.text('− Rp 150.000'), findsNWidgets(2));
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
    expect(find.text('Pencairan'), findsOneWidget);
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
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Pencairan'), findsOneWidget);
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

  testWidgets('refreshing keeps the list on screen with a spinner below it',
      (tester) async {
    await pumpView(tester);
    await tester.pumpAndSettle();
    final reload = Completer<Either<NetworkException, List<Pencairan>>>();
    when(() => useCases.getRiwayat(any())).thenAnswer((_) => reload.future);

    await tester.tap(find.byTooltip('Muat ulang'));
    await tester.pump();

    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    reload.complete(Right([_row(), _row(id: 'p-2')]));
    await tester.pumpAndSettle();

    expect(find.text('Pencairan'), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    verify(() => useCases.getRiwayat(any())).called(2);
  });
}
