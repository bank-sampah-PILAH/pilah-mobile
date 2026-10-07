import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';

abstract class HargaRemoteDataSource {
  Future<List<HargaModel>> getHarga();
  Future<void> addHarga(HargaModel harga);
  Future<void> updateHarga(HargaModel harga);
  Future<void> deactivateHarga(String id);
  Future<void> activateHarga(String id);
  Future<void> ubahHarga(UbahHarga perubahan);
}
