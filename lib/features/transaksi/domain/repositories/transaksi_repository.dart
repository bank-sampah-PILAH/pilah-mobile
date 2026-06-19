import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

abstract class TransaksiRepository {
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> getTransaksi();
  Future<Either<NetworkException, void>> addTransaksi(TransaksiEntity transaksi);
}
