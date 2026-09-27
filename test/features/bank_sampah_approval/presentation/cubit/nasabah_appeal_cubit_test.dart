import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';

class _MockAppealMembershipUseCase extends Mock
    implements AppealMembershipUseCase {}

void main() {
  late _MockAppealMembershipUseCase useCase;
  late NasabahAppealCubit cubit;

  setUp(() {
    useCase = _MockAppealMembershipUseCase();
    cubit = NasabahAppealCubit(useCase);
  });

  blocTest<NasabahAppealCubit, NasabahAppealState>(
    'emits Submitting then Success on success',
    build: () {
      when(() => useCase.execute('bank-1'))
          .thenAnswer((_) async => const Right(null));
      return cubit;
    },
    act: (cubit) => cubit.submit('bank-1'),
    expect: () => [
      const NasabahAppealSubmitting(),
      const NasabahAppealSuccess(),
    ],
  );

  blocTest<NasabahAppealCubit, NasabahAppealState>(
    'emits Submitting then Failure on failure',
    build: () {
      final failure = NetworkException.handleBadResponse(null);
      when(() => useCase.execute('bank-1'))
          .thenAnswer((_) async => Left(failure));
      return cubit;
    },
    act: (cubit) => cubit.submit('bank-1'),
    expect: () => [
      const NasabahAppealSubmitting(),
      isA<NasabahAppealFailure>(),
    ],
  );
}
