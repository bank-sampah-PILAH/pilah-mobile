import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_state.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

final _request = EditPencairanRequest(
  id: 'p-1',
  nominal: 150000,
  metode: MetodePencairan.transfer,
  tanggal: DateTime(2026, 9, 21),
  keterangan: 'Ditransfer',
  alasan: 'Salah ketik',
);

const _updated = Pencairan(
  id: 'p-1',
  nasabahNama: 'Ahmad Ridwan',
  nominal: 150000,
  metode: MetodePencairan.transfer,
  tanggal: null,
  keterangan: 'Ditransfer',
  status: 'tercatat',
  saldoSebelum: 465600,
  saldoSesudah: 315600,
  diperbarui: true,
);

UnprocessableEntityException _unprocessable(Map<String, dynamic> errors) =>
    UnprocessableEntityException(
      message: (errors.values.first as List).first.toString(),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/pencairan/p-1'),
        statusCode: 422,
        data: {'errors': errors},
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(_request));

  late _MockUseCases useCases;

  setUp(() => useCases = _MockUseCases());

  blocTest<EditPencairanCubit, EditPencairanState>(
    'saves the edit and keeps the updated pencairan',
    build: () {
      when(() => useCases.editPencairan(_request))
          .thenAnswer((_) async => const Right(_updated));
      return EditPencairanCubit(useCases);
    },
    act: (cubit) => cubit.submit(_request),
    expect: () => const [
      EditPencairanState(status: EditStatus.submitting),
      EditPencairanState(status: EditStatus.success, updated: _updated),
    ],
  );

  blocTest<EditPencairanCubit, EditPencairanState>(
    'shows field rejections from the server next to their fields',
    build: () {
      when(() => useCases.editPencairan(_request)).thenAnswer(
        (_) async => Left(_unprocessable({
          'nominal': ['Saldo nasabah tidak mencukupi untuk perubahan ini'],
          'tanggal': ['Tanggal pencairan tidak boleh di masa depan'],
        })),
      );
      return EditPencairanCubit(useCases);
    },
    act: (cubit) => cubit.submit(_request),
    expect: () => const [
      EditPencairanState(status: EditStatus.submitting),
      EditPencairanState(
        status: EditStatus.failure,
        fieldErrors: {
          'nominal': 'Saldo nasabah tidak mencukupi untuk perubahan ini',
          'tanggal': 'Tanggal pencairan tidak boleh di masa depan',
        },
      ),
    ],
  );

  blocTest<EditPencairanCubit, EditPencairanState>(
    'reports other failures, including an edit that changes nothing',
    build: () {
      when(() => useCases.editPencairan(_request)).thenAnswer(
        (_) async => Left(_unprocessable({
          'non_field_errors': ['Tidak ada data yang diubah'],
        })),
      );
      return EditPencairanCubit(useCases);
    },
    act: (cubit) => cubit.submit(_request),
    expect: () => const [
      EditPencairanState(status: EditStatus.submitting),
      EditPencairanState(
        status: EditStatus.failure,
        errorMessage: 'Tidak ada data yang diubah',
      ),
    ],
  );

  test('ignores a second submit while the first is in flight', () async {
    final pending = Completer<Either<NetworkException, Pencairan>>();
    when(() => useCases.editPencairan(any())).thenAnswer((_) => pending.future);
    final cubit = EditPencairanCubit(useCases);

    unawaited(cubit.submit(_request));
    await cubit.submit(_request);
    pending.complete(const Right(_updated));
    await Future<void>.delayed(Duration.zero);

    verify(() => useCases.editPencairan(any())).called(1);
    await cubit.close();
  });
}
