import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';

class _MockRepository extends Mock implements BankSampahApprovalRepository {}

void main() {
  test('AppealMembershipParams has value equality', () {
    const a = AppealMembershipParams(bankSampahId: 'bank-1', pesan: 'hi');
    const b = AppealMembershipParams(bankSampahId: 'bank-1', pesan: 'hi');
    const c = AppealMembershipParams(bankSampahId: 'bank-2', pesan: 'hi');

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });

  test('delegates to the repository with the bank sampah id', () async {
    final repository = _MockRepository();
    when(() => repository.appeal('bank-1', pesan: any(named: 'pesan')))
        .thenAnswer((_) async => const Right(null));

    final result = await AppealMembershipUseCase(repository)
        .execute(const AppealMembershipParams(bankSampahId: 'bank-1'));

    expect(result.isRight(), isTrue);
    verify(() => repository.appeal('bank-1', pesan: '')).called(1);
  });

  test('delegates the appeal message to the repository', () async {
    final repository = _MockRepository();
    when(() => repository.appeal('bank-1', pesan: any(named: 'pesan')))
        .thenAnswer((_) async => const Right(null));

    await AppealMembershipUseCase(repository).execute(
      const AppealMembershipParams(
          bankSampahId: 'bank-1', pesan: 'Dokumen sudah lengkap'),
    );

    verify(() => repository.appeal('bank-1', pesan: 'Dokumen sudah lengkap'))
        .called(1);
  });
}
