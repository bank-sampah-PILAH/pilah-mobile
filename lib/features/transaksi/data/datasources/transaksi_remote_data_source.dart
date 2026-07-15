import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';

abstract class TransaksiRemoteDataSource {
  Future<List<TransaksiGroupEntity>> getTransaksi(TransaksiFilter filter);
  Future<TransaksiCreated> addTransaksi(TransaksiRequest request);
  Future<TransaksiDetailEntity> getTransaksiDetail(String id);
  Future<TransaksiExport> exportTransaksi(TransaksiFilter filter);

  /// Resends the WhatsApp notification for a transaction. Returns the resulting
  /// app-side WA status ('sent' | 'failed' | 'pending'). A failed send is
  /// surfaced by the backend as an HTTP 400 and therefore thrown, not returned.
  Future<String> resendWa(String id);
}
