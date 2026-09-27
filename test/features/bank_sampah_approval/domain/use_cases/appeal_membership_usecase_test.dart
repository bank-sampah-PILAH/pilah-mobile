import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';

class _MockRepository extends Mock implements BankSampahApprovalRepository {}

void main() {
  test('delegates to the repository with the bank sampah id', () async {
    final repository = _MockRepository();
    when(() => repository.appeal('bank-1'))
        .thenAnswer((_) async => const Right(null));

    final result = await AppealMembershipUseCase(repository).execute('bank-1');

    expect(result.isRight(), isTrue);
    verify(() => repository.appeal('bank-1')).called(1);
  });
}
