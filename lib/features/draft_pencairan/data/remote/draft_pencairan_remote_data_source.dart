import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';

import '../../domain/model/draft_pencairan.dart';
import '../draft_pencairan_mapper.dart';

abstract class DraftPencairanRemoteDataSource {
  Future<List<Kandidat>> getKandidat({
    required String search,
    required KandidatUrutan urutan,
    required int saldoMin,
  });
  Future<List<DraftRingkasan>> getDrafts();
  Future<DraftPencairan> getDraft(String id);
  Future<DraftPencairan> createDraft(DraftInput input);
  Future<DraftPencairan> updateDraft(String id, DraftInput input);
  Future<DraftPencairan> cancelDraft(String id);
}

@LazySingleton(as: DraftPencairanRemoteDataSource)
class DraftPencairanRemoteDataSourceImpl
    implements DraftPencairanRemoteDataSource {
  final NetworkService _network;
  const DraftPencairanRemoteDataSourceImpl(this._network);

  static const String _path = '/api/v1/draft-pencairan';

  @override
  Future<List<Kandidat>> getKandidat({
    required String search,
    required KandidatUrutan urutan,
    required int saldoMin,
  }) async {
    final response = await _network.get(
      '$_path/kandidat',
      queryParams: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'ordering': urutan.apiValue,
        if (saldoMin > 0) 'saldo_min': saldoMin,
      },
    );
    return (response.data as List)
        .map(
            (row) => DraftPencairanMapper.kandidat(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DraftRingkasan>> getDrafts() async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final response = await _network.get(
        _path,
        queryParams: page == 1 ? null : {'page': page},
      );
      final data = response.data as Map<String, dynamic>;
      rows.addAll(
          (data['results'] as List? ?? const []).cast<Map<String, dynamic>>());
      final next = data['next'];
      if (next == null) break;
      final nextPage = Uri.tryParse(next.toString())?.queryParameters['page'];
      page = int.tryParse(nextPage ?? '') ?? page + 1;
    }
    return rows.map(DraftPencairanMapper.ringkasan).toList();
  }

  @override
  Future<DraftPencairan> getDraft(String id) async =>
      _draft(await _network.get('$_path/$id'));

  @override
  Future<DraftPencairan> createDraft(DraftInput input) async => _draft(
      await _network.post(_path, data: DraftPencairanMapper.body(input)));

  @override
  Future<DraftPencairan> updateDraft(String id, DraftInput input) async =>
      _draft(await _network.patch('$_path/$id',
          data: DraftPencairanMapper.body(input)));

  @override
  Future<DraftPencairan> cancelDraft(String id) async =>
      _draft(await _network.post('$_path/$id/batalkan'));

  DraftPencairan _draft(dynamic response) =>
      DraftPencairanMapper.draft(response.data as Map<String, dynamic>);
}
