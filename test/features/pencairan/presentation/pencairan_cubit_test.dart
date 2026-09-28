import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/pencairan_state.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

final _request = PencairanRequest(
  nasabahId: 'n-1',
  nominal: 200000,
  metode: MetodePencairan.tunai,
  tanggal: DateTime(2026, 9, 22),
);

const _created = Pencairan(
  id: 'p-1',
  nasabahNama: 'Ahmad Ridwan',
  nominal: 200000,
  metode: MetodePencairan.tunai,
  tanggal: null,
  keterangan: '',
  status: 'tercatat',
  saldoSebelum: 465600,
  saldoSesudah: 265600,
);

UnprocessableEntityException _unprocessable(Map<String, dynamic> errors) =>
    UnprocessableEntityException(
      message: (errors.values.first as List).first.toString(),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/pencairan'),
        statusCode: 422,
        data: {'errors': errors},
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(_request));

  late _MockUseCases useCases;

  setUp(() => useCases = _MockUseCases());

  group('loadSaldo', () {
    blocTest<PencairanCubit, PencairanState>(
      'loads the current saldo',
      build: () {
        when(() => useCases.getSaldo('n-1'))
            .thenAnswer((_) async => const Right(465600));
        return PencairanCubit(useCases);
      },
      act: (cubit) => cubit.loadSaldo('n-1'),
      expect: () => const [
        PencairanState(saldoStatus: SaldoStatus.loading),
        PencairanState(saldoStatus: SaldoStatus.loaded, saldo: 465600),
      ],
    );

    blocTest<PencairanCubit, PencairanState>(
      'reports a saldo that cannot be loaded',
      build: () {
        when(() => useCases.getSaldo('n-1')).thenAnswer(
          (_) async => Left(NotFoundException(message: 'Nasabah tidak ada')),
        );
        return PencairanCubit(useCases);
      },
      act: (cubit) => cubit.loadSaldo('n-1'),
      expect: () => const [
        PencairanState(saldoStatus: SaldoStatus.loading),
        PencairanState(
          saldoStatus: SaldoStatus.failure,
          errorMessage: 'Nasabah tidak ada',
        ),
      ],
    );
  });

  group('submit', () {
    blocTest<PencairanCubit, PencairanState>(
      'records the pencairan and moves the saldo to saldo sesudah',
      build: () {
        when(() => useCases.createPencairan(_request))
            .thenAnswer((_) async => const Right(_created));
        return PencairanCubit(useCases);
      },
      seed: () =>
          const PencairanState(saldoStatus: SaldoStatus.loaded, saldo: 465600),
      act: (cubit) => cubit.submit(_request),
      expect: () => const [
        PencairanState(
          saldoStatus: SaldoStatus.loaded,
          saldo: 465600,
          submitStatus: SubmitStatus.submitting,
        ),
        PencairanState(
          saldoStatus: SaldoStatus.loaded,
          saldo: 265600,
          submitStatus: SubmitStatus.success,
          created: _created,
        ),
      ],
    );

    blocTest<PencairanCubit, PencairanState>(
      'shows a nominal rejected by the server as a field error',
      build: () {
        when(() => useCases.createPencairan(_request)).thenAnswer(
          (_) async => Left(
            _unprocessable({
              'nominal': ['Saldo nasabah tidak mencukupi'],
            }),
          ),
        );
        return PencairanCubit(useCases);
      },
      seed: () =>
          const PencairanState(saldoStatus: SaldoStatus.loaded, saldo: 465600),
      act: (cubit) => cubit.submit(_request),
      skip: 1,
      expect: () => const [
        PencairanState(
          saldoStatus: SaldoStatus.loaded,
          saldo: 465600,
          submitStatus: SubmitStatus.failure,
          nominalError: 'Saldo nasabah tidak mencukupi',
        ),
      ],
    );

    blocTest<PencairanCubit, PencairanState>(
      'shows any other failure as a message',
      build: () {
        when(() => useCases.createPencairan(_request)).thenAnswer(
          (_) async => Left(
            _unprocessable({
              'nasabah_id': ['Nasabah tidak ditemukan atau tidak aktif'],
            }),
          ),
        );
        return PencairanCubit(useCases);
      },
      seed: () =>
          const PencairanState(saldoStatus: SaldoStatus.loaded, saldo: 465600),
      act: (cubit) => cubit.submit(_request),
      skip: 1,
      expect: () => const [
        PencairanState(
          saldoStatus: SaldoStatus.loaded,
          saldo: 465600,
          submitStatus: SubmitStatus.failure,
          errorMessage: 'Nasabah tidak ditemukan atau tidak aktif',
        ),
      ],
    );

    test('ignores a second submit while the first is in flight', () async {
      final pending = Completer<Either<NetworkException, Pencairan>>();
      when(() => useCases.createPencairan(any()))
          .thenAnswer((_) => pending.future);
      final cubit = PencairanCubit(useCases);

      final first = cubit.submit(_request);
      await cubit.submit(_request);
      pending.complete(const Right(_created));
      await first;

      verify(() => useCases.createPencairan(any())).called(1);
      await cubit.close();
    });

    blocTest<PencairanCubit, PencairanState>(
      'reads a nominal error sent as a bare string, not a list',
      build: () {
        when(() => useCases.createPencairan(_request)).thenAnswer(
          (_) async => Left(
            UnprocessableEntityException(
              message: 'Saldo nasabah tidak mencukupi',
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: '/api/v1/pencairan'),
                statusCode: 422,
                data: const {
                  'errors': {'nominal': 'Saldo nasabah tidak mencukupi'},
                },
              ),
            ),
          ),
        );
        return PencairanCubit(useCases);
      },
      act: (cubit) => cubit.submit(_request),
      skip: 1,
      expect: () => const [
        PencairanState(
          submitStatus: SubmitStatus.failure,
          nominalError: 'Saldo nasabah tidak mencukupi',
        ),
      ],
    );
  });

  group('clearNominalError', () {
    blocTest<PencairanCubit, PencairanState>(
      'drops the server error so an edited nominal stops showing it',
      build: () => PencairanCubit(useCases),
      seed: () => const PencairanState(
        saldoStatus: SaldoStatus.loaded,
        saldo: 465600,
        submitStatus: SubmitStatus.failure,
        nominalError: 'Saldo nasabah tidak mencukupi',
      ),
      act: (cubit) => cubit.clearNominalError(),
      expect: () => const [
        PencairanState(
          saldoStatus: SaldoStatus.loaded,
          saldo: 465600,
          submitStatus: SubmitStatus.failure,
        ),
      ],
    );

    blocTest<PencairanCubit, PencairanState>(
      'stays quiet when there is no server error to clear',
      build: () => PencairanCubit(useCases),
      seed: () =>
          const PencairanState(saldoStatus: SaldoStatus.loaded, saldo: 465600),
      act: (cubit) => cubit.clearNominalError(),
      expect: () => const <PencairanState>[],
    );
  });
}
