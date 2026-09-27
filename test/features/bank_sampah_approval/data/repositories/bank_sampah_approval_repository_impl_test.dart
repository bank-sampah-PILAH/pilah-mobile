import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/data/datasources/bank_sampah_approval_remote_data_source.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/data/repositories/bank_sampah_approval_repository_impl.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

class _MockRemoteDataSource extends Mock
    implements BankSampahApprovalRemoteDataSource {}

void main() {
  late _MockRemoteDataSource remote;
  late BankSampahApprovalRepositoryImpl repository;

  setUp(() {
    remote = _MockRemoteDataSource();
    repository = BankSampahApprovalRepositoryImpl(remote);
  });

  test('returns memberships from the remote source', () async {
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      bankSampahAlamat: 'Jl. Merdeka No. 10',
      status: MembershipStatus.approved,
      isActive: true,
    );
    when(() => remote.getMemberships()).thenAnswer((_) async => [membership]);

    final result = await repository.getMemberships();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => const []).single.id, 'membership-1');
  });

  test('maps a bad-response HTTP failure to NetworkException, not a throw',
      () async {
    when(() => remote.getMemberships())
        .thenAnswer((_) async => throw DioException(
              requestOptions: RequestOptions(path: '/api/v1/nasabah/me'),
              response: Response(
                requestOptions: RequestOptions(path: '/api/v1/nasabah/me'),
                statusCode: 500,
              ),
              type: DioExceptionType.badResponse,
            ));

    final result = await repository.getMemberships();

    expect(
      result.fold((failure) => failure, (_) => null),
      isA<InternalServerErrorException>(),
    );
  });

  test('appeals a membership through the remote source', () async {
    when(() => remote.appeal('bank-1', pesan: any(named: 'pesan')))
        .thenAnswer((_) async {});

    final result = await repository.appeal('bank-1');

    expect(result.isRight(), isTrue);
    verify(() => remote.appeal('bank-1', pesan: '')).called(1);
  });

  test('passes the appeal message through to the remote source', () async {
    when(() => remote.appeal('bank-1', pesan: any(named: 'pesan')))
        .thenAnswer((_) async {});

    await repository.appeal('bank-1', pesan: 'Dokumen sudah lengkap');

    verify(() => remote.appeal('bank-1', pesan: 'Dokumen sudah lengkap'))
        .called(1);
  });

  test('maps an appeal failure to NetworkException, not a throw', () async {
    when(() => remote.appeal('bank-1', pesan: any(named: 'pesan'))).thenAnswer(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/api/v1/onboarding/nasabah'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/onboarding/nasabah'),
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        ));

    final result = await repository.appeal('bank-1');

    expect(result.isLeft(), isTrue);
  });
}
