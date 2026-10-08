import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_state.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

DraftPencairan _batal(String id) => DraftPencairan(
      id: id,
      nama: 'Draft $id',
      status: DraftStatus.dibatalkan,
      potonganDefault: Potongan.nol,
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 7),
      items: const [],
      totalNominal: 0,
      totalPotongan: 0,
      totalDibayar: 0,
    );

DraftRingkasan _ringkasan(String id, DraftStatus status) => DraftRingkasan(
      id: id,
      nama: 'Draft $id',
      status: status,
      jumlahItem: 2,
      totalNominal: 100000,
      totalPotongan: 5000,
      totalDibayar: 95000,
    );

void main() {
  late _MockUseCases useCases;
  late DraftListCubit cubit;

  setUp(() {
    useCases = _MockUseCases();
    cubit = DraftListCubit(useCases);
  });

  test('loads the drafts, newest first as the server sends them', () async {
    final rows = [
      _ringkasan('d-2', DraftStatus.draft),
      _ringkasan('d-1', DraftStatus.dikonfirmasi),
    ];
    when(() => useCases.getDrafts()).thenAnswer((_) async => Right(rows));

    await cubit.load();

    expect(cubit.state.status, DraftListStatus.loaded);
    expect(cubit.state.drafts, rows);
  });

  test('the filter narrows the list to one status, or shows all', () async {
    when(() => useCases.getDrafts()).thenAnswer((_) async => Right([
          _ringkasan('d-1', DraftStatus.draft),
          _ringkasan('d-2', DraftStatus.dikonfirmasi),
          _ringkasan('d-3', DraftStatus.dibatalkan),
        ]));
    await cubit.load();

    cubit.setFilter(DraftStatus.draft);
    expect(cubit.state.tampil.map((d) => d.id), ['d-1']);

    cubit.setFilter(null);
    expect(cubit.state.tampil, hasLength(3));
  });

  test('a reload keeps the old list on screen while it fetches', () async {
    when(() => useCases.getDrafts())
        .thenAnswer((_) async => Right([_ringkasan('d-1', DraftStatus.draft)]));
    await cubit.load();

    final states = <DraftListState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.where((s) => s.drafts.isEmpty), isEmpty);
  });

  test('a failed load says why', () async {
    when(() => useCases.getDrafts())
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));

    await cubit.load();

    expect(cubit.state.status, DraftListStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('cancelling a draft reloads the list and reports no error', () async {
    when(() => useCases.getDrafts())
        .thenAnswer((_) async => Right([_ringkasan('d-1', DraftStatus.draft)]));
    await cubit.load();
    when(() => useCases.cancelDraft('d-1'))
        .thenAnswer((_) async => Right(_batal('d-1')));
    when(() => useCases.getDrafts()).thenAnswer(
        (_) async => Right([_ringkasan('d-1', DraftStatus.dibatalkan)]));

    final error = await cubit.batalkan('d-1');

    expect(error, isNull);
    expect(cubit.state.drafts.single.status, DraftStatus.dibatalkan);
  });

  test('a cancel that fails says why and leaves the list alone', () async {
    when(() => useCases.getDrafts())
        .thenAnswer((_) async => Right([_ringkasan('d-1', DraftStatus.draft)]));
    await cubit.load();
    when(() => useCases.cancelDraft('d-1'))
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));

    final error = await cubit.batalkan('d-1');

    expect(error, isNotNull);
    expect(cubit.state.drafts.single.status, DraftStatus.draft);
    verify(() => useCases.getDrafts()).called(1);
  });
}
