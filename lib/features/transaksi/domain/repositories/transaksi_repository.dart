import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

abstract class TransaksiRepository {
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> getTransaksi(
    TransaksiFilter filter,
  );
  Future<Either<NetworkException, TransaksiCreated>> addTransaksi(TransaksiRequest request);
  Future<Either<NetworkException, TransaksiDetailEntity>> getTransaksiDetail(String id);
  Future<Either<NetworkException, TransaksiExport>> exportTransaksi(
    TransaksiFilter filter,
  );
}
