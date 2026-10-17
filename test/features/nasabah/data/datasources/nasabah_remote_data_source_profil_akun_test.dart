import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source_impl.dart';

class _MockNetworkService extends Mock implements NetworkService {}

Response<dynamic> _respons(Object? data, String path) =>
    Response<dynamic>(requestOptions: RequestOptions(path: path), data: data);

void main() {
  late _MockNetworkService network;
  late NasabahRemoteDataSourceImpl dataSource;

  setUp(() {
    network = _MockNetworkService();
    dataSource = NasabahRemoteDataSourceImpl(network);
  });

  test('detail nasabah dibaca utuh: ringkasan, profil akun, dan bedanya',
      () async {
    when(() => network.get('/api/v1/nasabah/nasabah-1')).thenAnswer(
      (_) async => _respons({
        'ringkasan_transaksi': {'jumlah_transaksi': 3, 'total_kg': '4.00'},
        'profil_akun': {
          'nama': 'Budi Santosa',
          'jenis_kelamin': 'laki-laki',
          'tanggal_lahir': null,
          'alamat': 'Jl. Melati No. 99',
          'no_hp': '+628999999999',
        },
        'profil_berbeda': ['nama'],
      }, '/api/v1/nasabah/nasabah-1'),
    );

    final ringkasan = await dataSource.getNasabahRingkasan('nasabah-1');

    expect(ringkasan.jumlahTransaksi, 3);
    expect(ringkasan.profilAkun?.nama, 'Budi Santosa');
    expect(ringkasan.profilBerbeda, ['nama']);
  });

  test('sinkron profil memanggil endpoint sinkron milik nasabah itu', () async {
    when(() => network.post(any())).thenAnswer(
      (_) async => _respons({}, '/api/v1/nasabah/nasabah-1/sinkron-profil'),
    );

    await dataSource.sinkronProfil('nasabah-1');

    verify(() => network.post('/api/v1/nasabah/nasabah-1/sinkron-profil'))
        .called(1);
  });
}
