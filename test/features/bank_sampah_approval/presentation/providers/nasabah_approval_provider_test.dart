import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';

class _MockGetNasabahMembershipsUseCase extends Mock
    implements GetNasabahMembershipsUseCase {}

const _membership = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  bankSampahAlamat: 'Jl. Merdeka No. 10',
  status: MembershipStatus.pending,
  isActive: true,
);

void main() {
  test('initial state has value equality', () {
    expect(NasabahApprovalInitial(), NasabahApprovalInitial());
  });

  late _MockGetNasabahMembershipsUseCase useCase;
  late NasabahApprovalNotifier notifier;
  late ProviderContainer container;
  late ProviderSubscription<NasabahApprovalState> subscription;
  var disposed = false;

  setUp(() {
    useCase = _MockGetNasabahMembershipsUseCase();
    notifier = NasabahApprovalNotifier(useCase);
    container = ProviderContainer(
      overrides: [nasabahApprovalProvider.overrideWith(() => notifier)],
    );
    subscription = container.listen(nasabahApprovalProvider, (_, __) {});
    disposed = false;
  });

  tearDown(() {
    if (!disposed) {
      subscription.close();
      container.dispose();
    }
  });

  test('loads memberships and reports Loading then Loaded', () async {
    when(() => useCase.execute())
        .thenAnswer((_) async => const Right([_membership]));
    final states = <NasabahApprovalState>[];
    final changes = container.listen(
      nasabahApprovalProvider,
      (_, next) => states.add(next),
    );

    await notifier.load();
    changes.close();

    expect(states, [
      const NasabahApprovalLoading(),
      const NasabahApprovalLoaded([_membership]),
    ]);
  });

  test('reports an error when loading fails', () async {
    final failure = NetworkException.handleBadResponse(null);
    when(() => useCase.execute()).thenAnswer((_) async => Left(failure));
    final states = <NasabahApprovalState>[];
    final changes = container.listen(
      nasabahApprovalProvider,
      (_, next) => states.add(next),
    );

    await notifier.load();
    changes.close();

    expect(states.first, const NasabahApprovalLoading());
    expect(states.last, NasabahApprovalError(failure.displayMessage));
  });

  test('a silent initial load still reports Loading', () async {
    when(() => useCase.execute())
        .thenAnswer((_) async => const Right([_membership]));
    final states = <NasabahApprovalState>[];
    final changes = container.listen(
      nasabahApprovalProvider,
      (_, next) => states.add(next),
    );

    await notifier.load(silent: true);
    changes.close();

    expect(states, [
      const NasabahApprovalLoading(),
      const NasabahApprovalLoaded([_membership]),
    ]);
  });

  test('a silent refresh keeps loaded data visible', () async {
    var calls = 0;
    when(() => useCase.execute()).thenAnswer((_) async =>
        ++calls == 1 ? const Right([_membership]) : const Right([]));
    final states = <NasabahApprovalState>[];
    final changes = container.listen(
      nasabahApprovalProvider,
      (_, next) => states.add(next),
    );
    await notifier.load();
    states.clear();

    await notifier.load(silent: true);
    changes.close();

    expect(states, [const NasabahApprovalLoaded([])]);
  });

  test('a response after provider disposal is ignored', () async {
    final pending =
        Completer<Either<NetworkException, List<NasabahMembershipEntity>>>();
    when(() => useCase.execute()).thenAnswer((_) => pending.future);
    final request = notifier.load();
    await Future<void>.delayed(Duration.zero);
    subscription.close();
    container.dispose();
    disposed = true;
    pending.complete(const Right([_membership]));

    await expectLater(request, completes);
  });

  test('an older response cannot overwrite a newer refresh', () async {
    final first =
        Completer<Either<NetworkException, List<NasabahMembershipEntity>>>();
    final latest =
        Completer<Either<NetworkException, List<NasabahMembershipEntity>>>();
    var calls = 0;
    when(() => useCase.execute())
        .thenAnswer((_) => (++calls == 1 ? first : latest).future);

    final earlierRequest = notifier.load();
    final refresh = notifier.load(silent: true);
    latest.complete(const Right([]));
    await refresh;
    first.complete(const Right([_membership]));
    await earlierRequest;

    expect(container.read(nasabahApprovalProvider),
        const NasabahApprovalLoaded([]));
  });
}
