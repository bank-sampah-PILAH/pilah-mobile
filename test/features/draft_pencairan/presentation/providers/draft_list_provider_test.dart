import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/providers/draft_list_provider.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockRepository extends Mock implements DraftPencairanRepository {}

DraftRingkasan _ringkasan(String id, DraftStatus status) => DraftRingkasan(
      id: id,
      nama: 'Draft $id',
      status: status,
      jumlahItem: 2,
      totalNominal: 100000,
      totalPotongan: 5000,
      totalDibayar: 95000,
    );

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

void main() {
  late _MockRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<DraftListState> keepAlive;
  late DraftListNotifier notifier;

  setUp(() {
    repository = _MockRepository();
    container = ProviderContainer(
      overrides: [
        draftListProvider.overrideWith(() => DraftListNotifier(repository)),
      ],
    );
    keepAlive =
        container.listen(draftListProvider, (_, __) {}, fireImmediately: true);
    notifier = container.read(draftListProvider.notifier);
  });

  tearDown(() {
    keepAlive.close();
    container.dispose();
  });

  test('loads the drafts, newest first as the server sends them', () async {
    final rows = [
      _ringkasan('d-2', DraftStatus.draft),
      _ringkasan('d-1', DraftStatus.dikonfirmasi),
    ];
    when(() => repository.getDrafts()).thenAnswer((_) async => Right(rows));

    await notifier.load();

    final state = container.read(draftListProvider);
    expect(state.status, DraftListStatus.loaded);
    expect(state.drafts, rows);
  });

  test('a failed load says why', () async {
    when(() => repository.getDrafts())
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));

    await notifier.load();

    final state = container.read(draftListProvider);
    expect(state.status, DraftListStatus.failure);
    expect(state.errorMessage, isNotNull);
  });

  test('a reload keeps the old list on screen while it fetches', () async {
    when(() => repository.getDrafts())
        .thenAnswer((_) async => Right([_ringkasan('d-1', DraftStatus.draft)]));
    await notifier.load();

    final pending = Completer<Either<NetworkException, List<DraftRingkasan>>>();
    when(() => repository.getDrafts()).thenAnswer((_) => pending.future);
    final states = <DraftListState>[];
    final sub =
        container.listen(draftListProvider, (_, next) => states.add(next));

    final loading = notifier.load();
    expect(container.read(draftListProvider).drafts, hasLength(1));
    pending.complete(Right([
      _ringkasan('d-1', DraftStatus.draft),
      _ringkasan('d-2', DraftStatus.dibatalkan),
    ]));
    await loading;
    sub.close();

    expect(states.where((state) => state.drafts.isEmpty), isEmpty);
    expect(container.read(draftListProvider).drafts, hasLength(2));
  });

  test('cancelling a draft reloads the list and reports no error', () async {
    var reads = 0;
    when(() => repository.getDrafts()).thenAnswer((_) async => Right([
          _ringkasan(
              'd-1', reads++ == 0 ? DraftStatus.draft : DraftStatus.dibatalkan),
        ]));
    when(() => repository.cancelDraft('d-1'))
        .thenAnswer((_) async => Right(_batal('d-1')));
    await notifier.load();

    expect(await notifier.batalkan('d-1'), isNull);
    expect(container.read(draftListProvider).drafts.single.status,
        DraftStatus.dibatalkan);
  });

  test('a cancel that fails says why and leaves the list alone', () async {
    when(() => repository.getDrafts())
        .thenAnswer((_) async => Right([_ringkasan('d-1', DraftStatus.draft)]));
    await notifier.load();
    when(() => repository.cancelDraft('d-1'))
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));

    expect(await notifier.batalkan('d-1'), isNotNull);
    expect(container.read(draftListProvider).drafts.single.status,
        DraftStatus.draft);
    verify(() => repository.getDrafts()).called(1);
  });

  test('ignores load and cancel results after the route is disposed', () async {
    final pendingLoad =
        Completer<Either<NetworkException, List<DraftRingkasan>>>();
    when(() => repository.getDrafts()).thenAnswer((_) => pendingLoad.future);
    final disposedContainer = ProviderContainer(
      overrides: [
        draftListProvider.overrideWith(() => DraftListNotifier(repository)),
      ],
    );
    final loadSubscription = disposedContainer
        .listen(draftListProvider, (_, __) {}, fireImmediately: true);
    final loading = disposedContainer.read(draftListProvider.notifier).load();
    loadSubscription.close();
    disposedContainer.dispose();
    pendingLoad.complete(Right([_ringkasan('d-1', DraftStatus.draft)]));
    await loading;
    verify(() => repository.getDrafts()).called(1);

    final pendingCancel = Completer<Either<NetworkException, DraftPencairan>>();
    when(() => repository.cancelDraft('d-1'))
        .thenAnswer((_) => pendingCancel.future);
    final cancelContainer = ProviderContainer(
      overrides: [
        draftListProvider.overrideWith(() => DraftListNotifier(repository)),
      ],
    );
    final cancelSubscription = cancelContainer
        .listen(draftListProvider, (_, __) {}, fireImmediately: true);
    final cancelling =
        cancelContainer.read(draftListProvider.notifier).batalkan('d-1');
    cancelSubscription.close();
    cancelContainer.dispose();
    pendingCancel.complete(Right(_batal('d-1')));
    expect(await cancelling, isNull);
    verifyNever(() => repository.getDrafts());
  });

  test('provider resolves its repository from DI', () async {
    di.registerSingleton<DraftPencairanRepository>(repository);
    final defaultContainer = ProviderContainer();
    final sub = defaultContainer.listen(draftListProvider, (_, __) {},
        fireImmediately: true);
    addTearDown(() async {
      sub.close();
      defaultContainer.dispose();
      await di.unregister<DraftPencairanRepository>();
    });

    expect(defaultContainer.read(draftListProvider).status,
        DraftListStatus.loading);
  });
}
