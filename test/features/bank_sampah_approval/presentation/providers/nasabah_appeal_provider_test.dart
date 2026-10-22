import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_appeal_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockAppealMembershipUseCase extends Mock
    implements AppealMembershipUseCase {}

void main() {
  late _MockAppealMembershipUseCase useCase;
  late ProviderContainer container;
  late ProviderSubscription<NasabahAppealState> keepAlive;
  late NasabahAppealNotifier notifier;

  setUp(() {
    useCase = _MockAppealMembershipUseCase();
    container = ProviderContainer(
      overrides: [
        nasabahAppealProvider
            .overrideWith(() => NasabahAppealNotifier(useCase)),
      ],
    );
    keepAlive = container.listen(nasabahAppealProvider, (_, __) {},
        fireImmediately: true);
    notifier = container.read(nasabahAppealProvider.notifier);
  });

  tearDown(() {
    keepAlive.close();
    container.dispose();
  });

  test('emits Submitting then Success on success', () async {
    when(() => useCase
            .execute(const AppealMembershipParams(bankSampahId: 'bank-1')))
        .thenAnswer((_) async => const Right(null));
    final states = <NasabahAppealState>[];
    final sub =
        container.listen(nasabahAppealProvider, (_, next) => states.add(next));

    await notifier.submit('bank-1');
    sub.close();

    expect(states, [
      const NasabahAppealSubmitting(),
      const NasabahAppealSuccess(),
    ]);
  });

  test('emits Submitting then Failure on failure', () async {
    final failure = NetworkException.handleBadResponse(null);
    when(() => useCase
            .execute(const AppealMembershipParams(bankSampahId: 'bank-1')))
        .thenAnswer((_) async => Left(failure));
    final states = <NasabahAppealState>[];
    final sub =
        container.listen(nasabahAppealProvider, (_, next) => states.add(next));

    await notifier.submit('bank-1');
    sub.close();

    expect(states, [
      const NasabahAppealSubmitting(),
      NasabahAppealFailure(failure.displayMessage),
    ]);
  });

  test('forwards the appeal message to the use case', () async {
    when(() => useCase.execute(const AppealMembershipParams(
            bankSampahId: 'bank-1', pesan: 'Dokumen sudah lengkap')))
        .thenAnswer((_) async => const Right(null));

    await notifier.submit('bank-1', pesan: 'Dokumen sudah lengkap');

    verify(() => useCase.execute(const AppealMembershipParams(
        bankSampahId: 'bank-1', pesan: 'Dokumen sudah lengkap'))).called(1);
  });

  test('ignores a response after the detail route is disposed', () async {
    final response = Completer<Either<NetworkException, void>>();
    when(() => useCase
            .execute(const AppealMembershipParams(bankSampahId: 'bank-1')))
        .thenAnswer((_) => response.future);

    final disposedContainer = ProviderContainer(
      overrides: [
        nasabahAppealProvider
            .overrideWith(() => NasabahAppealNotifier(useCase)),
      ],
    );
    final subscription = disposedContainer
        .listen(nasabahAppealProvider, (_, __) {}, fireImmediately: true);
    final pending =
        disposedContainer.read(nasabahAppealProvider.notifier).submit('bank-1');
    expect(disposedContainer.read(nasabahAppealProvider),
        const NasabahAppealSubmitting());
    subscription.close();
    disposedContainer.dispose();
    response.complete(const Right(null));

    await pending;
  });

  test('provider resolves its use case from DI', () async {
    di.registerSingleton<AppealMembershipUseCase>(useCase);
    final defaultContainer = ProviderContainer();
    final sub = defaultContainer.listen(nasabahAppealProvider, (_, __) {},
        fireImmediately: true);
    addTearDown(() async {
      sub.close();
      defaultContainer.dispose();
      await di.unregister<AppealMembershipUseCase>();
    });

    expect(defaultContainer.read(nasabahAppealProvider),
        const NasabahAppealIdle());
  });
}
