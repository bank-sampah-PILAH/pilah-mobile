import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/superadmin/data/datasources/superadmin_remote_data_source.dart';
import 'package:pilah_mobile/features/superadmin/data/models/bank_sampah_model.dart';

@LazySingleton(as: SuperadminRemoteDataSource)
class SuperadminRemoteDataSourceImpl implements SuperadminRemoteDataSource {
  final NetworkService networkService;

  SuperadminRemoteDataSourceImpl(this.networkService);

  static const String _path = '/api/v1/superadmin/bank-sampah';

  @override
  Future<List<BankSampahModel>> getBankSampah(String status) async {
    final response = await networkService.get(_path, queryParams: {'status': status});
    // This endpoint returns {count, results} (not DRF-paginated envelope).
    final data = response.data;
    final List<dynamic> results =
        data is Map<String, dynamic> ? (data['results'] as List? ?? []) : (data as List);
    return results
        .map((json) => BankSampahModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> approve(String id, String? catatan) async {
    await networkService.post(
      '$_path/$id/approve',
      data: {if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan.trim()},
    );
  }

  @override
  Future<void> reject(String id, String? catatan) async {
    await networkService.post(
      '$_path/$id/reject',
      data: {if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan.trim()},
    );
  }
}
