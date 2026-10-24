import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/constants/endpoints.dart';
import 'package:pilah_mobile/features/perbandingan_harga/domain/entities/perbandingan_harga_entities.dart';

abstract class PerbandinganHargaRemoteDataSource {
  Future<PerbandinganHargaEntity> compare({
    required String jenisSampahId,
    required List<String> bankIds,
  });
}

@LazySingleton(as: PerbandinganHargaRemoteDataSource)
class PerbandinganHargaRemoteDataSourceImpl
    implements PerbandinganHargaRemoteDataSource {
  final NetworkService networkService;

  PerbandinganHargaRemoteDataSourceImpl(this.networkService);

  @override
  Future<PerbandinganHargaEntity> compare({
    required String jenisSampahId,
    required List<String> bankIds,
  }) async {
    final response = await networkService.get(
      Endpoints.bankSampahHargaPerbandingan,
      queryParams: {
        'jenis_sampah_id': jenisSampahId,
        'bank_ids': bankIds.join(','),
      },
    );
    return PerbandinganHargaEntity.fromJson(
        response.data as Map<String, dynamic>);
  }
}
