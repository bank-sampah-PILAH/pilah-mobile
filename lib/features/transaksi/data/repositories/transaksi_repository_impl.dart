import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart';

@LazySingleton(as: TransaksiRepository)
class TransaksiRepositoryImpl implements TransaksiRepository {
  final TransaksiRemoteDataSource remoteDataSource;

  TransaksiRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> getTransaksi() {
    return apiCall<List<TransaksiGroupEntity>>(
      func: remoteDataSource.getTransaksi(),
      mapper: (result) => (result as List).cast<TransaksiGroupEntity>(),
    );
  }

  @override
  Future<Either<NetworkException, TransaksiCreated>> addTransaksi(TransaksiRequest request) {
    return apiCall<TransaksiCreated>(
      func: remoteDataSource.addTransaksi(request),
      mapper: (result) => result as TransaksiCreated,
    );
  }

  @override
  Future<Either<NetworkException, TransaksiDetailEntity>> getTransaksiDetail(String id) {
    return apiCall<TransaksiDetailEntity>(
      func: remoteDataSource.getTransaksiDetail(id),
      mapper: (result) => result as TransaksiDetailEntity,
    );
  }
}
