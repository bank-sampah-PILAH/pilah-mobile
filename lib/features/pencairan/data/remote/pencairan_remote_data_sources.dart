import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/riwayat_pencairan_filter.dart';
import '../model/mapper/pencairan_mapper.dart';
import '../model/responses/pencairan_response.dart';

abstract class PencairanRemoteDataSources {
  Future<int> getSaldo(String nasabahId);
  Future<PencairanResponse> createPencairan(PencairanRequest request);
  Future<List<PencairanResponse>> getRiwayat(RiwayatPencairanFilter filter);
}

@LazySingleton(as: PencairanRemoteDataSources)
class PencairanRemoteDataSourceImpl implements PencairanRemoteDataSources {
  final NetworkService _networkService;
  const PencairanRemoteDataSourceImpl(this._networkService);

  static const String _path = '/api/v1/pencairan';

  @override
  Future<int> getSaldo(String nasabahId) async {
    final response =
        await _networkService.get('/api/v1/nasabah/$nasabahId/saldo');
    final json = response.data as Map<String, dynamic>;
    return PencairanMapper.rupiah(json['total_saldo']);
  }

  @override
  Future<PencairanResponse> createPencairan(PencairanRequest request) async {
    final keterangan = request.keterangan?.trim();
    final response = await _networkService.post(
      _path,
      data: {
        'nasabah_id': request.nasabahId,
        'nominal': request.nominal,
        'metode': request.metode.name,
        'tanggal': request.tanggal.toUtc().toIso8601String(),
        if (keterangan != null && keterangan.isNotEmpty)
          'keterangan': keterangan,
      },
    );
    return PencairanResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<PencairanResponse>> getRiwayat(
    RiwayatPencairanFilter filter,
  ) async {
    final response = await _networkService.get(
      _path,
      queryParams: filter.toQueryParams(),
    );
    final data = response.data;
    final List<dynamic> rows = data is Map<String, dynamic>
        ? (data['results'] as List? ?? const [])
        : (data as List);
    return rows
        .map((row) => PencairanResponse.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
