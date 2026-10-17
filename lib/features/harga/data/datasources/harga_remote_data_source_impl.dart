import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source.dart';
import 'package:pilah_mobile/core/utils/formatter/date_time_formatter.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';

@LazySingleton(as: HargaRemoteDataSource)
class HargaRemoteDataSourceImpl implements HargaRemoteDataSource {
  final NetworkService networkService;

  HargaRemoteDataSourceImpl(this.networkService);

  @override
  Future<List<HargaModel>> getHarga() async {
    // `status=semua` returns both active and inactive so the active/inactive
    // tabs can filter client-side; without it the backend defaults to `aktif`
    // and deactivated items vanish from the list entirely.
    final response = await networkService.get(
      '/api/v1/jenis-sampah',
      queryParams: {'status': 'semua', 'page_size': 100},
    );
    final Map<String, dynamic> responseData = response.data;
    final List<dynamic> data = responseData['results'];
    return data.map((json) => HargaModel.fromJson(json)).toList();
  }

  @override
  Future<void> addHarga(HargaModel harga) async {
    await networkService.post('/api/v1/jenis-sampah', data: harga.toJson());
  }

  @override
  Future<void> updateHarga(HargaModel harga) async {
    await networkService.put('/api/v1/jenis-sampah/${harga.id}',
        data: harga.toUpdateJson());
  }

  @override
  Future<void> deactivateHarga(String id) async {
    await networkService
        .patch('/api/v1/jenis-sampah/$id/status', data: {'is_active': false});
  }

  @override
  Future<void> activateHarga(String id) async {
    await networkService
        .patch('/api/v1/jenis-sampah/$id/status', data: {'is_active': true});
  }

  @override
  Future<void> ubahHarga(UbahHarga perubahan) async {
    final berlakuMulai = perubahan.berlakuMulai;
    await networkService.post(
      '/api/v1/jenis-sampah/${perubahan.id}/harga',
      data: {
        'harga_per_kg': perubahan.harga.toString(),
        if (berlakuMulai != null)
          'berlaku_mulai': isoDenganOffset(berlakuMulai),
      },
    );
  }
}
