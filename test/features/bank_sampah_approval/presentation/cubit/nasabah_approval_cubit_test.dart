import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';

class _MockGetNasabahMembershipsUseCase extends Mock
    implements GetNasabahMembershipsUseCase {}

const _membership = NasabahMembershipEntity(
  id: 'membership-1',
  bankSampahId: 'bank-1',
  bankSampahNama: 'Bank Sampah Sejahtera',
  bankSampahKota: 'Bandung',
  status: MembershipStatus.pending,
  isActive: true,
);

void main() {
  late _MockGetNasabahMembershipsUseCase useCase;
  late NasabahApprovalCubit cubit;

  setUp(() {
    useCase = _MockGetNasabahMembershipsUseCase();
    cubit = NasabahApprovalCubit(useCase);
  });

  blocTest<NasabahApprovalCubit, NasabahApprovalState>(
    'emits Loading then Loaded on success',
    build: () {
      when(() => useCase.execute())
          .thenAnswer((_) async => const Right([_membership]));
      return cubit;
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const NasabahApprovalLoading(),
      const NasabahApprovalLoaded([_membership]),
    ],
  );

  blocTest<NasabahApprovalCubit, NasabahApprovalState>(
    'emits Loading then Error on failure',
    build: () {
      final failure = NetworkException.handleBadResponse(null);
      when(() => useCase.execute()).thenAnswer((_) async => Left(failure));
      return cubit;
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const NasabahApprovalLoading(),
      isA<NasabahApprovalError>(),
    ],
  );

  blocTest<NasabahApprovalCubit, NasabahApprovalState>(
    'silent reload skips the Loading state when data is already loaded',
    build: () {
      when(() => useCase.execute())
          .thenAnswer((_) async => const Right([_membership]));
      return cubit;
    },
    seed: () => const NasabahApprovalLoaded([]),
    act: (cubit) => cubit.load(silent: true),
    expect: () => [
      const NasabahApprovalLoaded([_membership]),
    ],
  );
}
