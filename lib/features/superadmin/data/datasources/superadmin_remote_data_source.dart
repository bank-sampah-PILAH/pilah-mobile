import 'package:pilah_mobile/features/superadmin/data/models/bank_sampah_model.dart';

abstract class SuperadminRemoteDataSource {
  Future<List<BankSampahModel>> getBankSampah(String status);
  Future<void> approve(String id, String? catatan);
  Future<void> reject(String id, String? catatan);
}
