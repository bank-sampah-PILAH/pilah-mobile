import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';

abstract class JadwalRemoteDataSource {
  Future<List<JadwalModel>> getJadwal();
  Future<JadwalModel> createJadwal(JadwalModel jadwal);
  Future<JadwalModel> updateJadwal(JadwalModel jadwal);
  Future<JadwalModel> transition(String id, String action);
}

@LazySingleton(as: JadwalRemoteDataSource)
class JadwalRemoteDataSourceImpl implements JadwalRemoteDataSource {
  final NetworkService networkService;

  JadwalRemoteDataSourceImpl(this.networkService);

  @override
  Future<List<JadwalModel>> getJadwal() async {
    final schedules = <JadwalModel>[];
    var page = 1;
    while (true) {
      final response = await networkService.get(
        '/api/v1/jadwal',
        queryParams: {'page_size': 100, if (page > 1) 'page': page},
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? const [];
      schedules.addAll(results.map(
        (item) => JadwalModel.fromJson(item as Map<String, dynamic>),
      ));
      if (data['next'] == null) return schedules;
      page++;
    }
  }

  @override
  Future<JadwalModel> createJadwal(JadwalModel jadwal) async {
    final response =
        await networkService.post('/api/v1/jadwal', data: jadwal.toJson());
    return JadwalModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<JadwalModel> updateJadwal(JadwalModel jadwal) async {
    final response = await networkService.patch(
      '/api/v1/jadwal/${jadwal.id}',
      data: jadwal.toJson(),
    );
    return JadwalModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<JadwalModel> transition(String id, String action) async {
    final response = await networkService.post('/api/v1/jadwal/$id/$action');
    return JadwalModel.fromJson(response.data as Map<String, dynamic>);
  }
}
