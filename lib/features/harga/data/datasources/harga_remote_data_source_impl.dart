import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source.dart';
import 'package:pilah_mobile/features/harga/data/models/harga_model.dart';

@LazySingleton(as: HargaRemoteDataSource)
class HargaRemoteDataSourceImpl implements HargaRemoteDataSource {
  final NetworkService networkService;

  HargaRemoteDataSourceImpl(this.networkService);

  @override
  Future<List<HargaModel>> getHarga() async {
    final response = await networkService.get('/api/v1/jenis-sampah');
    final List<dynamic> data = response.data;
    return data.map((json) => HargaModel.fromJson(json)).toList();
  }

  @override
  Future<void> addHarga(HargaModel harga) async {
    await networkService.post('/api/v1/jenis-sampah', data: harga.toJson());
  }

  @override
  Future<void> updateHarga(HargaModel harga) async {
    await networkService.put('/api/v1/jenis-sampah/${harga.id}', data: harga.toJson());
  }

  @override
  Future<void> deactivateHarga(String id) async {
    await networkService.patch('/api/v1/jenis-sampah/$id', data: {'is_active': false});
  }
}
