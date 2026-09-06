import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/superadmin/data/datasources/superadmin_remote_data_source.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';
import 'package:pilah_mobile/features/superadmin/domain/repositories/superadmin_repository.dart';

@LazySingleton(as: SuperadminRepository)
class SuperadminRepositoryImpl implements SuperadminRepository {
  final SuperadminRemoteDataSource remoteDataSource;

  SuperadminRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, List<BankSampahEntity>>> getBankSampah(
      String status) {
    return apiCall<List<BankSampahEntity>>(
      func: remoteDataSource.getBankSampah(status),
      mapper: (result) => (result as List).cast<BankSampahEntity>(),
    );
  }

  @override
  Future<Either<NetworkException, void>> approve(String id,
      {String? catatan}) async {
    try {
      await remoteDataSource.approve(id, catatan);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> reject(String id,
      {String? catatan}) async {
    try {
      await remoteDataSource.reject(id, catatan);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
