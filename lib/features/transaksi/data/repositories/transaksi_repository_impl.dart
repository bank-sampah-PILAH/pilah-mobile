import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_local_data_source.dart';
import 'package:pilah_mobile/features/transaksi/data/models/transaksi_model.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart';

@LazySingleton(as: TransaksiRepository)
class TransaksiRepositoryImpl implements TransaksiRepository {
  final TransaksiLocalDataSource localDataSource;

  TransaksiRepositoryImpl(this.localDataSource);

  @override
  Future<Either<NetworkException, List<TransaksiGroupEntity>>> getTransaksi() async {
    try {
      final result = await localDataSource.getTransaksi();
      return Right(result);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }

  @override
  Future<Either<NetworkException, void>> addTransaksi(TransaksiEntity transaksi) async {
    try {
      final items = transaksi.items
          .map((i) => ItemSetoranModel(
                jenis: i.jenis,
                berat: i.berat,
                harga: i.harga,
                subtotal: i.subtotal,
              ))
          .toList();

      final model = TransaksiModel(
        initials: transaksi.initials,
        avatarColor: transaksi.avatarColor,
        textColor: transaksi.textColor,
        name: transaksi.name,
        subtitle: transaksi.subtitle,
        amount: transaksi.amount,
        isWaSuccess: transaksi.isWaSuccess,
        time: transaksi.time,
        balance: transaksi.balance,
        items: items,
      );

      await localDataSource.addTransaksi(model);
      return const Right(null);
    } on Exception catch (e) {
      return Left(NetworkException.handleException(e));
    }
  }
}
