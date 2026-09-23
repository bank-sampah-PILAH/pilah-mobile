import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';

class _MockNetworkService extends Mock implements NetworkService {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  test('creates a schedule with the API payload', () async {
    final network = _MockNetworkService();
    final payload = <String, dynamic>{};
    when(() => network.post(
          '/api/v1/jadwal',
          data: any(named: 'data'),
        )).thenAnswer((invocation) async {
      payload.addAll(invocation.namedArguments[#data] as Map<String, dynamic>);
      return _response(_schedule('created'));
    });

    final created =
        await JadwalRemoteDataSourceImpl(network).createJadwal(_model('new'));

    expect(created.id, 'created');
    expect(payload['lokasi'], 'Balai Warga');
    verify(() => network.post('/api/v1/jadwal', data: any(named: 'data')))
        .called(1);
  });

  test('updates the requested schedule', () async {
    final network = _MockNetworkService();
    when(() => network.patch(
          '/api/v1/jadwal/schedule-1',
          data: any(named: 'data'),
        )).thenAnswer((_) async => _response(_schedule('schedule-1')));

    final updated = await JadwalRemoteDataSourceImpl(network)
        .updateJadwal(_model('schedule-1'));

    expect(updated.id, 'schedule-1');
    verify(() => network.patch(
          '/api/v1/jadwal/schedule-1',
          data: any(named: 'data'),
        )).called(1);
  });

  test('posts lifecycle changes to their action endpoint', () async {
    final network = _MockNetworkService();
    when(() => network.post('/api/v1/jadwal/schedule-1/terbitkan'))
        .thenAnswer((_) async => _response(_schedule('schedule-1')));

    final updated = await JadwalRemoteDataSourceImpl(network)
        .transition('schedule-1', 'terbitkan');

    expect(updated.id, 'schedule-1');
    verify(() => network.post('/api/v1/jadwal/schedule-1/terbitkan')).called(1);
  });

  test('loads every page of schedules', () async {
    final network = _MockNetworkService();
    final queries = <Map<String, dynamic>>[];
    when(() => network.get(
          '/api/v1/jadwal',
          queryParams: any(named: 'queryParams'),
        )).thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#queryParams] as Map<String, dynamic>;
      queries.add(query);
      final page = queries.length;
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/jadwal'),
        data: {
          'next': page == 1
              ? 'https://api.pilah.test/api/v1/jadwal?page=2&page_size=100'
              : null,
          'results': [_schedule('schedule-$page')],
        },
      );
    });

    final schedules = await JadwalRemoteDataSourceImpl(network).getJadwal();

    expect(
        schedules.map((schedule) => schedule.id), ['schedule-1', 'schedule-2']);
    expect(queries, [
      {'page_size': 100},
      {'page_size': 100, 'page': 2},
    ]);
  });
}

Response<Map<String, dynamic>> _response(Map<String, dynamic> data) =>
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(path: '/api/v1/jadwal'),
      data: data,
    );

JadwalModel _model(String id) => JadwalModel.fromJson(_schedule(id));

Map<String, dynamic> _schedule(String id) => {
      'id': id,
      'bank_sampah_id': 'bank-1',
      'jenis_kegiatan': 'penimbangan',
      'mulai_pada': '2026-10-10T01:00:00Z',
      'selesai_pada': '2026-10-10T03:00:00Z',
      'lokasi': 'Balai Warga',
    };
