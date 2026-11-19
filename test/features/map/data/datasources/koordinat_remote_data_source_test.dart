import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/map/data/datasources/koordinat_remote_data_source.dart';

import '../../../../support/stub_api.dart';

const _path = '/api/v1/bank-sampah/resolve-koordinat';

/// PIL-326: the app asks the backend for a coordinate instead of calling a
/// geocoder or Google itself.
void main() {
  late StubApi api;
  late KoordinatRemoteDataSource source;

  setUp(() {
    api = StubApi();
    source = KoordinatRemoteDataSourceImpl(api.network);
  });

  test('dariAlamat sends the address and city, and reads the full payload',
      () async {
    api.on('POST', _path, json: {
      'latitude': -6.3703237,
      'longitude': 106.8270541,
      'sumber': 'geocode',
      'alamat_hasil': 'Fakultas Ilmu Komputer UI, Depok',
      'akurasi_m': 30,
    });

    final hasil = await source.dariAlamat(
      alamat: 'Fasilkom UI',
      kota: 'Depok',
    );

    expect(hasil.latitude, -6.3703237);
    expect(hasil.longitude, 106.8270541);
    expect(hasil.sumber, 'geocode');
    expect(hasil.alamatHasil, 'Fakultas Ilmu Komputer UI, Depok');
    expect(hasil.akurasiM, 30);

    final body = api.requests.single.json as Map<String, dynamic>;
    expect(body['sumber'], 'alamat');
    expect(body['alamat'], 'Fasilkom UI');
    expect(body['kota'], 'Depok');
  });

  test('an empty city is left out of the request', () async {
    api.on('POST', _path, json: {
      'latitude': -6.2,
      'longitude': 106.8,
      'sumber': 'geocode',
    });

    await source.dariAlamat(alamat: 'Bank Depok', kota: '   ');

    final body = api.requests.single.json as Map<String, dynamic>;
    expect(body.containsKey('kota'), isFalse);
  });

  test('dariTautan trims the link and tolerates a link-only answer', () async {
    api.on('POST', _path, json: {
      'latitude': -6.3697742,
      'longitude': 106.8269168,
      'sumber': 'tautan',
    });

    final hasil = await source.dariTautan('  https://maps.app.goo.gl/abc  ');

    expect(hasil.latitude, -6.3697742);
    expect(hasil.sumber, 'tautan');
    expect(hasil.alamatHasil, isNull);
    expect(hasil.akurasiM, isNull);

    final body = api.requests.single.json as Map<String, dynamic>;
    expect(body['sumber'], 'tautan');
    expect(body['tautan'], 'https://maps.app.goo.gl/abc');
  });
}
