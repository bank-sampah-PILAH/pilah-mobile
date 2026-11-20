import 'package:dartz/dartz.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import '../entities/transaksi_filter.dart';
import '../entities/aktivitas_page.dart';

abstract class AktivitasRepository {
  Future<Either<NetworkException, AktivitasPage>> history(
      TransaksiFilter filter);
}
