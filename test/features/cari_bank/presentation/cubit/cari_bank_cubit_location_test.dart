import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/cubit/cari_bank_cubit.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/cari_bank_support.dart';
import '../../../../support/stub_api.dart';

const _directory = '/api/v1/bank-sampah';

class _FakeLocationService extends Mock implements LocationService {}

class _FakeStorage extends Mock implements AppStorage {}

void main() {
  late StubApi api;
  late CariBankCubit cubit;
  late _FakeLocationService location;
  late _FakeStorage storage;

  setUpAll(() {
    registerFallbackValue('any');
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    api = StubApi();
    cubit = buildCariBankCubit(api);
    location = _FakeLocationService();
    storage = _FakeStorage();
    di.allowReassignment = true;
    di.registerSingleton<LocationService>(location);
    addTearDown(() => di.unregister<LocationService>());
  });

  tearDown(() => cubit.close());

  test('pilihDariPeta sends the coordinate trio with sort=distance', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));

    await cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
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

    await cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    cubit.pilihRadiusKm(10);
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query['radius_km'], '10.0');
  });

  test('muatBerikutnya carries the location params too', () async {
    api.on('GET', _directory,
        json: bankSampahPage([bankRow('b1', 'Bank Garis')],
            count: 2, hasNext: true));
    await cubit.pilihDariPeta((latitude: -6.36, longitude: 106.82));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    api.on('GET', _directory, json: bankSampahPage(const [], count: 2));
    await cubit.muatBerikutnya();

    expect(api.last.query['page'], '2');
    expect(api.last.query['radius_km'], '5.0');
    expect(api.last.query['sort'], 'distance');
  });

  test('a manual pick persists into local storage', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    final kubik = buildCariBankCubitWithStorage(api, storage);
    when(() => storage.put(any(), any())).thenAnswer((_) async {});
    // ignore: body_might_complete_normally_nullable
    addTearDown(kubik.close);

    await kubik.pilihDariPeta((latitude: -6.36, longitude: 106.82));

    verify(() => storage.put('cari_bank_manual_lat', -6.36)).called(1);
    verify(() => storage.put('cari_bank_manual_lng', 106.82)).called(1);
  });

  test('a saved manual pick wins the page-open default over the device fix',
      () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    final kubik = buildCariBankCubitWithStorage(api, storage);
    addTearDown(kubik.close);
    when(() => storage.get<double>(any())).thenAnswer(
      (inv) async => switch (inv.positionalArguments.first as String) {
        'cari_bank_manual_lat' => -6.36,
        'cari_bank_manual_lng' => 106.82,
        _ => 7.5,
      },
    );
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -1.0, longitude: -1.0));

    await kubik.muatLokasiAwal();
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query['latitude'], '-6.36');
    expect(api.last.query['radius_km'], '7.5');
    verifyNever(() => location.currentLocation());
  });

  test('without a saved pick the device fix becomes the origin', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    final kubik = buildCariBankCubitWithStorage(api, storage);
    addTearDown(kubik.close);
    when(() => storage.get<double>(any())).thenAnswer((_) async => null);
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -7.9, longitude: 110.3));

    await kubik.muatLokasiAwal();
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(api.last.query['latitude'], '-7.9');
    expect(api.last.query['radius_km'], '5.0');
  });

  test('no storage and no fix degrades quietly to keyword mode', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    when(() => location.currentLocation()).thenAnswer((_) async => null);

    await cubit.muatLokasiAwal();
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    // The denial never re-queries; the page's own initial load() has run.
    expect(api.requests, isEmpty);
  });

  test('a saved pick switches the cubit into location mode', () async {
    api.on('GET', _directory, json: bankSampahPage(const [], count: 0));
    expect(cubit.modeLokasi, isFalse);

    await cubit.pilihDariPeta((latitude: -6.3, longitude: 106.8));
    await Future<void>.delayed(CariBankCubit.jedaPencarian * 2);

    expect(cubit.modeLokasi, isTrue);
    expect(api.last.query['sort'], 'distance');
  });
}
