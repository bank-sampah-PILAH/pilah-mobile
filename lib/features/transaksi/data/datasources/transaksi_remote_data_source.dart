import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

abstract class TransaksiRemoteDataSource {
  Future<List<TransaksiGroupEntity>> getTransaksi();
  Future<TransaksiCreated> addTransaksi(TransaksiRequest request);
  Future<TransaksiDetailEntity> getTransaksiDetail(String id);
}
