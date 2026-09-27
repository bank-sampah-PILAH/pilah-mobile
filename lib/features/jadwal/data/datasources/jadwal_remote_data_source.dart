import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_page_model.dart';

abstract class JadwalRemoteDataSource {
  Future<JadwalPageModel> getJadwal({required int page, DateTime? date});
  Future<Set<DateTime>> getCalendarDates(DateTime startDate, DateTime endDate);
  Future<JadwalModel> createJadwal(JadwalModel jadwal);
  Future<JadwalModel> updateJadwal(JadwalModel jadwal);
  Future<JadwalModel> transition(String id, String action);
}

@LazySingleton(as: JadwalRemoteDataSource)
class JadwalRemoteDataSourceImpl implements JadwalRemoteDataSource {
  final NetworkService networkService;

  JadwalRemoteDataSourceImpl(this.networkService);

  @override
  Future<JadwalPageModel> getJadwal({required int page, DateTime? date}) async {
    final response = await networkService.get(
      '/api/v1/jadwal',
      queryParams: {
        'page_size': 20,
        'page': page,
        if (date != null) 'date': _formatDate(date),
      },
    );
    return JadwalPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Set<DateTime>> getCalendarDates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await networkService.get(
      '/api/v1/jadwal/calendar-dates',
      queryParams: {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['dates'] as List<dynamic>? ?? const []).map((value) {
      final date = DateTime.parse(value.toString());
      return DateTime(date.year, date.month, date.day);
    }).toSet();
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

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
