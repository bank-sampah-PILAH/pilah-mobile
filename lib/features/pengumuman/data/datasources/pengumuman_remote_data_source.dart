import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_model.dart';
import 'package:pilah_mobile/features/pengumuman/data/models/pengumuman_page_model.dart';

abstract class PengumumanRemoteDataSource {
  Future<PengumumanPageModel> getPengumuman(
      {required int page, String? status});
  Future<PengumumanModel> createPengumuman(PengumumanModel pengumuman);
  Future<PengumumanModel> updatePengumuman(PengumumanModel pengumuman);
  Future<PengumumanModel> terbitkan(
    String id, {
    DateTime? terbitPada,
    DateTime? masaBerlakuHingga,
  });
  Future<PengumumanModel> tarik(String id);
  Future<void> deletePengumuman(String id);
}

@LazySingleton(as: PengumumanRemoteDataSource)
class PengumumanRemoteDataSourceImpl implements PengumumanRemoteDataSource {
  final NetworkService networkService;

  PengumumanRemoteDataSourceImpl(this.networkService);

  @override
  Future<PengumumanPageModel> getPengumuman({
    required int page,
    String? status,
  }) async {
    final response = await networkService.get(
      '/api/v1/pengumuman',
      queryParams: {
        'page_size': 20,
        'page': page,
        if (status != null) 'status': status,
      },
    );
    return PengumumanPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PengumumanModel> createPengumuman(PengumumanModel pengumuman) async {
    final response = await networkService.post(
      '/api/v1/pengumuman',
      data: pengumuman.toJson(),
    );
    return PengumumanModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PengumumanModel> updatePengumuman(PengumumanModel pengumuman) async {
    final response = await networkService.patch(
      '/api/v1/pengumuman/${pengumuman.id}',
      data: pengumuman.toJson(),
    );
    return PengumumanModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PengumumanModel> terbitkan(
    String id, {
    DateTime? terbitPada,
    DateTime? masaBerlakuHingga,
  }) async {
    final response = await networkService.post(
      '/api/v1/pengumuman/$id/terbitkan',
      data: {
        if (terbitPada != null)
          'terbit_pada': terbitPada.toUtc().toIso8601String(),
        if (masaBerlakuHingga != null)
          'masa_berlaku_hingga': masaBerlakuHingga.toUtc().toIso8601String(),
      },
    );
    return PengumumanModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PengumumanModel> tarik(String id) async {
    final response = await networkService.post('/api/v1/pengumuman/$id/tarik');
    return PengumumanModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deletePengumuman(String id) async {
    await networkService.delete('/api/v1/pengumuman/$id');
  }
}
