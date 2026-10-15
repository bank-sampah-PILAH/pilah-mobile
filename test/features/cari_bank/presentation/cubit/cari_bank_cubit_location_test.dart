import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';

class _FakeLocationService extends Mock implements LocationService {}

void main() {
  late StubApi api;
  late CariBankCubit cubit;
  late _FakeLocationService location;

  setUp(() {
    api = StubApi();
    cubit = buildCariBankCubit(api);
    location = _FakeLocationService();
    di.allowReassignment = true;
    di.registerSingleton<LocationService>(location);
    addTearDown(() => di.unregister<LocationService>());
  });

  tearDown(() => cubit.close());

  test('pilihDariPeta sends the coordinate trio with sort=distance', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query, {
      'page': '1',
      'latitude': '-6.36',
      'longitude': '106.82',
      'radius_km': '5.0',
      'sort': 'distance',
    });
  });

  test('the radius chip change reloads with the new radius', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    cubit.pilihRadiusKm(10);
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query['radius_km'], '10.0');
  });

  test('muatBerikutnya carries the location params too', () async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')],
            count: 2, hasNext: true));
    cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    api.on('GET', _directory, json: bankSampahPage(const [], count: 2));
    await cubit.muatBerikutnya();

    expect(api.last.query['page'], '2');
    expect(api.last.query['radius_km'], '5.0');
    expect(api.last.query['sort'], 'distance');
  });

  test('hapusLokasi drops the trio and returns to keyword mode', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    cubit.hapusLokasi();
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query, {'page': '1'});
  });

  test('dekatSaya with a granted fix enters location mode via the service',
      () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -6.4, longitude: 106.9));

    await cubit.pilihLokasiSaya();
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query['latitude'], '-6.4');
  });

  test('dekatSaya with no fix degrades quietly to keyword mode', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    when(() => location.currentLocation()).thenAnswer((_) async => null);

    await cubit.load();
    api.requests.clear();
    await cubit.pilihLokasiSaya();
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    // The denial never re-queries; the keyword result from `load` stays.
    expect(api.requests, isEmpty);
  });
}
