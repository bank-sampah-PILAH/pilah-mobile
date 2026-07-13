import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

abstract class TransaksiRemoteDataSource {
  Future<List<TransaksiGroupEntity>> getTransaksi(TransaksiFilter filter);
  Future<TransaksiCreated> addTransaksi(TransaksiRequest request);
  Future<TransaksiDetailEntity> getTransaksiDetail(String id);
  Future<TransaksiExport> exportTransaksi(TransaksiFilter filter);
}
