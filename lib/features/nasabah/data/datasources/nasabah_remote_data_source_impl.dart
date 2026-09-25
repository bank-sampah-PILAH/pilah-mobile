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

  /// Batas `max_page_size` backend; dipakai picker yang menarik satu kali ambil.
  static const int _batasPicker = 100;

  @override
  Future<NasabahPage> getNasabah({
    int page = 1,
    String status = 'aktif',
    String? search,
  }) async {
    // Penyaringan dilakukan server supaya paginasi tetap benar: menyaring di
    // aplikasi hanya akan menyaring halaman yang kebetulan sudah dimuat.
    // Ukuran halaman mengikuti default server, tidak dipaksa dari sini.
    final response = await networkService.get(
      _path,
      queryParams: {
        'status': status,
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _halaman(response.data);
  }

  @override
  Future<NasabahPage> getActiveNasabah() async {
    final response = await networkService.get(
      _path,
      queryParams: {'status': 'aktif', 'page_size': _batasPicker},
    );
    return _halaman(response.data);
  }

  /// Membaca bentuk paginasi DRF `{count, next, previous, results}`.
  ///
  /// Endpoint daftar nasabah selalu terpaginasi karena paginasi dipasang global
  /// di backend, jadi tidak ada cabang untuk daftar polos.
  NasabahPage _halaman(dynamic data) {
    final amplop = data as Map<String, dynamic>;
    final results = amplop['results'] as List? ?? [];
    return NasabahPage(
      items: results
          .map((json) => NasabahModel.fromJson(json as Map<String, dynamic>))
          .toList(),
      // `count` adalah total di server; `next` null berarti ini halaman akhir.
      totalCount: (amplop['count'] as num?)?.toInt() ?? results.length,
      hasMore: amplop['next'] != null,
    );
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

  @override
  Future<void> approveNasabah(String id, String? catatan) async {
    await networkService.post(
      '$_path/$id/approve',
      data: {
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim()
      },
    );
  }

  @override
  Future<void> rejectNasabah(String id, String? catatan) async {
    await networkService.post(
      '$_path/$id/reject',
      data: {
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan': catatan.trim()
      },
    );
  }
}
