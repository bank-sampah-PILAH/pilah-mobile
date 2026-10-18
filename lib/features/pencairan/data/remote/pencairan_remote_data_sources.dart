import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/riwayat_pencairan_filter.dart';
import '../model/responses/pencairan_response.dart';
import '../model/responses/revisi_pencairan_response.dart';

abstract class PencairanRemoteDataSources {
  Future<List<PencairanResponse>> getRiwayat(RiwayatPencairanFilter filter);
  Future<PencairanResponse> editPencairan(EditPencairanRequest request);
  Future<RiwayatRevisiPencairanResponse> getRevisi(String id);
}

@LazySingleton(as: PencairanRemoteDataSources)
class PencairanRemoteDataSourceImpl implements PencairanRemoteDataSources {
  final NetworkService _networkService;
  const PencairanRemoteDataSourceImpl(this._networkService);

  static const String _path = '/api/v1/pencairan';

  @override
  Future<PencairanResponse> editPencairan(EditPencairanRequest request) async {
    final response = await _networkService.patch(
      '$_path/${request.id}',
      data: {
        'nominal': request.nominal,
        'metode': request.metode.name,
        'tanggal': request.tanggal.toUtc().toIso8601String(),
        'keterangan': request.keterangan.trim(),
        'alasan': request.alasan.trim(),
      },
    );
    return PencairanResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<RiwayatRevisiPencairanResponse> getRevisi(String id) async {
    final response = await _networkService.get('$_path/$id/riwayat');
    return RiwayatRevisiPencairanResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<PencairanResponse>> getRiwayat(
    RiwayatPencairanFilter filter,
  ) async {
    final queryParams = filter.toQueryParams();
    final rows = <dynamic>[];
    final requestedPages = <int>{};
    var page = 1;

    while (true) {
      if (!requestedPages.add(page)) {
        throw StateError('Pencairan pagination repeated page $page');
      }
      final response = await _networkService.get(
        _path,
        queryParams: page == 1 ? queryParams : {...queryParams, 'page': page},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        rows.addAll(data as List);
        break;
      }

      rows.addAll(data['results'] as List? ?? const []);
      // A caller that only wants the newest few (the dashboard preview, PIL-282)
      // stops here: the backend already orders pencairan newest-first, so the
      // first page already holds the answer and walking the rest of the
      // history would only be thrown away.
      if (filter.limit != null) break;
      final next = data['next'];
      if (next == null) break;

      final nextPage = Uri.tryParse(next.toString())?.queryParameters['page'];
      page = int.tryParse(nextPage ?? '') ?? page + 1;
    }

    final limit = filter.limit;
    final limited =
        limit != null && rows.length > limit ? rows.take(limit).toList() : rows;
    return limited
        .map((row) => PencairanResponse.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
