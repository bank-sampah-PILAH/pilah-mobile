import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';
import 'nasabah_approval_support.dart';

class _MockGetNasabahMembershipsUseCase extends Mock
    implements GetNasabahMembershipsUseCase {}

GetNasabahMembershipsUseCase buildApprovedMembershipUseCase() {
  final useCase = _MockGetNasabahMembershipsUseCase();
  when(() => useCase.execute()).thenAnswer((_) async => const Right([
        NasabahMembershipEntity(
          id: 'membership',
          bankSampahId: 'bank',
          bankSampahNama: 'Bank Sampah Melati',
          bankSampahKota: 'Bandung',
          bankSampahAlamat: 'Jl. Melati',
          status: MembershipStatus.approved,
          isActive: true,
        ),
      ]));
  return useCase;
}

TestNasabahApprovalNotifier buildApprovedMembershipNotifier() =>
    TestNasabahApprovalNotifier(
      initialState: const NasabahApprovalLoaded([
        NasabahMembershipEntity(
          id: 'membership',
          bankSampahId: 'bank',
          bankSampahNama: 'Bank Sampah Melati',
          bankSampahKota: 'Bandung',
          bankSampahAlamat: 'Jl. Melati',
          status: MembershipStatus.approved,
          isActive: true,
        ),
      ]),
      useCase: buildApprovedMembershipUseCase(),
    );
