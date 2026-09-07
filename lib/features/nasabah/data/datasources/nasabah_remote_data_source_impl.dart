import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart';
import 'package:pilah_mobile/features/nasabah/data/models/nasabah_model.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

@LazySingleton(as: NasabahRemoteDataSource)
class NasabahRemoteDataSourceImpl implements NasabahRemoteDataSource {
  final NetworkService networkService;

  NasabahRemoteDataSourceImpl(this.networkService);

  static const String _path = '/api/v1/nasabah';

  @override
  Future<List<NasabahModel>> getNasabah() async {
    // `status=semua` returns both active and inactive so the active/inactive
    // tabs can be filtered client-side; page_size is maxed to fetch in one call.
    final response = await networkService.get(
      _path,
      queryParams: {'status': 'semua', 'page_size': 100},
    );
    final data = response.data;
    final List<dynamic> results = data is Map<String, dynamic>
        ? (data['results'] as List? ?? [])
        : (data as List);
    return results
        .map((json) => NasabahModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<NasabahRingkasan> getNasabahRingkasan(String id) async {
    final response = await networkService.get('$_path/$id');
    final ringkasan =
        (response.data as Map<String, dynamic>)['ringkasan_transaksi']
                as Map<String, dynamic>? ??
            <String, dynamic>{};
    return NasabahRingkasanMapper.fromJson(ringkasan);
  }

  @override
  Future<NasabahModel> addNasabah(NasabahRequest request) async {
    final response = await networkService.post(
      _path,
      data: NasabahModel.toPayload(request),
    );
    return NasabahModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<NasabahModel> updateNasabah(String id, NasabahRequest request) async {
    final response = await networkService.put(
      '$_path/$id',
      data: NasabahModel.toPayload(request),
    );
    return NasabahModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> setStatus(String id, bool isActive) async {
    await networkService
        .patch('$_path/$id/status', data: {'is_active': isActive});
  }
}
