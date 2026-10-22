import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/revisi_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/providers/revisi_pencairan_provider.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

const _pencairan = Pencairan(
  id: 'p-1',
  nasabahNama: 'Ayu Nasabah',
  nominal: 100000,
  metode: MetodePencairan.transfer,
  tanggal: null,
  keterangan: '',
  status: 'tercatat',
  saldoSebelum: 200000,
  saldoSesudah: 100000,
);

const _riwayat = RiwayatRevisiPencairan(pencairan: _pencairan, revisi: []);

void main() {
  late _MockUseCases useCases;
  late ProviderContainer container;
  late ProviderSubscription<RevisiPencairanState> subscription;
  late RevisiPencairanNotifier notifier;

  setUp(() {
    useCases = _MockUseCases();
    container = ProviderContainer(overrides: [
      revisiPencairanProvider.overrideWith(
        () => RevisiPencairanNotifier(useCases),
      ),
    ]);
    subscription = container.listen(revisiPencairanProvider, (_, __) {});
    notifier = container.read(revisiPencairanProvider.notifier);
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test('loads the current version and revisions', () async {
    when(() => useCases.getRevisi('p-1'))
        .thenAnswer((_) async => const Right(_riwayat));

    await notifier.load('p-1');

    expect(
        container.read(revisiPencairanProvider),
        const RevisiPencairanState(
            status: RevisiStatus.loaded, riwayat: _riwayat));
  });

  test('returns the server failure', () async {
    when(() => useCases.getRevisi('p-1')).thenAnswer(
      (_) async => Left(NotFoundException(message: 'Riwayat tidak ditemukan')),
    );

    await notifier.load('p-1');

    expect(
      container.read(revisiPencairanProvider),
      const RevisiPencairanState(
        status: RevisiStatus.failure,
        errorMessage: 'Riwayat tidak ditemukan',
      ),
    );
  });

  test('ignores an in-flight result after the provider is disposed', () async {
    final pending =
        Completer<Either<NetworkException, RiwayatRevisiPencairan>>();
    when(() => useCases.getRevisi('p-1')).thenAnswer((_) => pending.future);
    final loading = notifier.load('p-1');

    subscription.close();
    container.dispose();
    pending.complete(const Right(_riwayat));
    await loading;
  });
}
