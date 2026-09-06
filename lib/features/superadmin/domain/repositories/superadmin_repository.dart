import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';

abstract class SuperadminRepository {
  Future<Either<NetworkException, List<BankSampahEntity>>> getBankSampah(
      String status);
  Future<Either<NetworkException, void>> approve(String id, {String? catatan});
  Future<Either<NetworkException, void>> reject(String id, {String? catatan});
}
