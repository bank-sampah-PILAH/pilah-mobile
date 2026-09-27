import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';

class _MockRepository extends Mock implements BankSampahApprovalRepository {}

void main() {
  test('delegates to the repository', () async {
    final repository = _MockRepository();
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      status: MembershipStatus.approved,
      isActive: true,
    );
    when(() => repository.getMemberships())
        .thenAnswer((_) async => const Right([membership]));

    final result = await GetNasabahMembershipsUseCase(repository).execute();

    expect(result.getOrElse(() => const []).single.id, 'membership-1');
    verify(() => repository.getMemberships()).called(1);
  });
}
