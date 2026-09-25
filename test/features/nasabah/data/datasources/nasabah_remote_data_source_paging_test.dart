import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source_impl.dart';

class _MockNetworkService extends Mock implements NetworkService {}

Response<dynamic> _halaman({
  required List<Map<String, dynamic>> results,
  int? count,
  String? next,
}) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/v1/nasabah'),
      data: {
        'count': count ?? results.length,
        'next': next,
        'previous': null,
        'results': results,
      },
    );

Map<String, dynamic> _nasabahJson(String nomor) => {
      'id': nomor,
      'nomor': nomor,
      'nama': 'Nasabah $nomor',
      'no_hp': '+6281234567890',
      'alamat': 'Jl. Melati',
      'is_active': true,
      'status': 'approved',
    };

void main() {
  late _MockNetworkService network;
  late NasabahRemoteDataSourceImpl dataSource;

  setUp(() {
    network = _MockNetworkService();
    dataSource = NasabahRemoteDataSourceImpl(network);
  });

  test('reports another page is available when the API sends a next link',
      () async {
    when(() => network.get(any(), queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => _halaman(
              results: [_nasabahJson('NAS-0001'), _nasabahJson('NAS-0002')],
              count: 42,
              next: 'https://api.example.com/api/v1/nasabah?page=2',
            ));

    final halaman = await dataSource.getNasabah();

    expect(halaman.items, hasLength(2));
    expect(halaman.totalCount, 42);
    expect(halaman.hasMore, isTrue);
  });

  test('asks the server for the requested page, tab, and search term',
      () async {
    when(() => network.get(any(), queryParams: any(named: 'queryParams')))
        .thenAnswer((_) async => _halaman(results: []));

    await dataSource.getNasabah(page: 2, status: 'tidak_aktif', search: 'budi');

    final params = verify(() => network.get(
          '/api/v1/nasabah',
          queryParams: captureAny(named: 'queryParams'),
        )).captured.single as Map<String, dynamic>;

    expect(params['page'], 2);
    expect(params['status'], 'tidak_aktif');
    expect(params['search'], 'budi');
    // Ukuran halaman dibiarkan mengikuti default server; memaksa 100 di sini
    // adalah cara lama yang membuat daftar terpotong diam-diam.
    expect(params.containsKey('page_size'), isFalse);
  });
}
