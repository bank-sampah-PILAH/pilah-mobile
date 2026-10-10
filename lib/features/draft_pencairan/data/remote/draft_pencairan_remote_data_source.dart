import 'dart:typed_data';

import 'package:dio/dio.dart' show Response;

import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';

import '../../domain/model/draft_pencairan.dart';
import '../draft_pencairan_mapper.dart';

abstract class DraftPencairanRemoteDataSource {
  Future<List<Kandidat>> getKandidat({
    required String search,
    required KandidatUrutan urutan,
    required int saldoMin,
    required bool termasukKosong,
  });
  Future<List<DraftRingkasan>> getDrafts();
  Future<DraftPencairan> getDraft(String id);
  Future<DraftPencairan> createDraft(DraftInput input);
  Future<DraftPencairan> updateDraft(String id, DraftInput input);
  Future<DraftPencairan> cancelDraft(String id);
  Future<DraftPencairan> confirmDraft(String id);
  Future<DraftExport> exportPratinjau(DraftInput input, ExportBerkas berkas);
  Future<DraftExport> exportDraft(String id, ExportBerkas berkas);
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
    required bool termasukKosong,
  }) async {
    final response = await _network.get(
      '$_path/kandidat',
      queryParams: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'ordering': urutan.apiValue,
        if (saldoMin > 0) 'saldo_min': saldoMin,
        if (termasukKosong) 'termasuk_kosong': true,
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

  @override
  Future<DraftPencairan> confirmDraft(String id) async =>
      _draft(await _network.post('$_path/$id/konfirmasi'));

  @override
  Future<DraftExport> exportPratinjau(
    DraftInput input,
    ExportBerkas berkas,
  ) async {
    final response = await _network.postBytes(
      '$_path/export',
      queryParams: {'berkas': berkas.name},
      data: DraftPencairanMapper.body(input),
    );
    return _berkas(response, berkas);
  }

  @override
  Future<DraftExport> exportDraft(String id, ExportBerkas berkas) async {
    final response = await _network.getBytes(
      '$_path/$id/export',
      queryParams: {'berkas': berkas.name},
    );
    return _berkas(response, berkas);
  }

  DraftExport _berkas(Response response, ExportBerkas berkas) {
    final bytes = Uint8List.fromList((response.data as List).cast<int>());
    final filename = RegExp(r'filename="?([^"]+)"?')
            .firstMatch(response.headers.value('content-disposition') ?? '')
            ?.group(1) ??
        'draft_pencairan_${DateTime.now().millisecondsSinceEpoch}.${berkas.name}';
    return DraftExport(bytes: bytes, filename: filename);
  }

  DraftPencairan _draft(dynamic response) =>
      DraftPencairanMapper.draft(response.data as Map<String, dynamic>);
}
