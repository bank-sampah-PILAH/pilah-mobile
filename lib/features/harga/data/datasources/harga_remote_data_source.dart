import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';

abstract class HargaRemoteDataSource {
  Future<List<HargaModel>> getHarga();
  Future<void> addHarga(HargaModel harga);
  Future<void> updateHarga(HargaModel harga);
  Future<void> deactivateHarga(String id);
}
