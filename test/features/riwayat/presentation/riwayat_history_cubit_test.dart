import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/riwayat/domain/entities/riwayat_entities.dart';
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart';
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart';
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart';

class _Repository extends Mock implements RiwayatRepository {}

void main() {
  late _Repository repo;
  late RiwayatHistoryCubit cubit;
  late GetRiwayatHistoryUseCase historyUseCase;
  late GetRiwayatSetoranDetailUseCase detailUseCase;

  setUp(() {
    registerFallbackValue(
      Left<NetworkException, RiwayatHistory>(NetworkException(message: 'x')),
    );
    repo = _Repository();
    historyUseCase = GetRiwayatHistoryUseCase(repo);
    detailUseCase = GetRiwayatSetoranDetailUseCase(repo);
    cubit = RiwayatHistoryCubit(historyUseCase, detailUseCase);
  });

  NasabahActivity activity(String id) => NasabahActivity.fromJson({
        'id': id,
        'tanggal': '2026-09-23T08:00:00+07:00',
        'tipe': 'setoran',
        'total_nilai': '12500.00',
      });

  test('copyWith keeps every field the caller did not pass', () {
    const state = RiwayatHistoryState(
      status: RiwayatHistoryStatus.loaded,
      activities: [],
      hasNext: true,
      page: 2,
      error: 'offline',
    );

    final cleared = state.copyWith(error: null);
    expect(cleared.error, isNull,
        reason: 'null explicitly means "clear", the sentinel means "keep"');
    expect(cleared.status, RiwayatHistoryStatus.loaded);
    expect(cleared.hasNext, isTrue);
    expect(cleared.page, 2);

    // The lib callers only ever pass status; the untouched-default path
    // (every other field carried over) still has to behave.
    final onlyStatus = state.copyWith(status: RiwayatHistoryStatus.loading);
    expect(onlyStatus.status, RiwayatHistoryStatus.loading);
    expect(onlyStatus.hasNext, isTrue);
    expect(onlyStatus.page, 2);
    expect(onlyStatus.error, 'offline');
  });

  test('a retry after a failure clears the error from the state', () async {
    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async => Left(NetworkException(message: 'offline')),
    );
    await cubit.loadHistory('member-b', reset: true);
    expect(cubit.state.error, 'offline');

    when(() => repo.history(any(), page: any(named: 'page'))).thenAnswer(
      (_) async => Right(RiwayatHistory([activity('a')], false)),
    );
    await cubit.loadHistoryCurrent(reset: true);

    // The stale message must be gone — a state carrying both rows and an
    // error would read as "data loaded, but something is still wrong".
    expect(cubit.state.error, isNull);
    expect(cubit.state.status, RiwayatHistoryStatus.loaded);
  });
}
