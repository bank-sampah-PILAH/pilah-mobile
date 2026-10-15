import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';

import '../../../support/onboarding_support.dart';
import '../../../support/stub_api.dart';

const _bank = '/api/v1/onboarding/bank-sampah';

void main() {
  late StubApi api;
  late OnboardingCubit cubit;
  late File photo;

  setUp(() {
    api = StubApi();
    cubit = buildOnboardingCubit(api);
    photo = File('${Directory.systemTemp.path}/onboarding_foto.jpg')
      ..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    await cubit.close();
    if (photo.existsSync()) photo.deleteSync();
  });

  RegisterBankSampahRequest bankRequest(
          {({double latitude, double longitude})? lokasi}) =>
      RegisterBankSampahRequest(
        nama: 'Bank Melati',
        alamat: 'Jl. Melati 1',
        noHpPic: '0812',
        fotoKegiatanPath: photo.path,
        lokasi: lokasi,
      );

  test('a picked location rides the registration as strings', () async {
    api.on('POST', _bank, json: {'next_step': 'pending'});

    await cubit.registerBankSampah(
      bankRequest(
        lokasi: (latitude: -6.362829, longitude: 106.828655),
      ),
    );

    final form = api.last.body as dynamic;
    final fields = {
      for (final f in (form as dynamic).fields as List<dynamic>)
        (f as dynamic).key as String: (f as dynamic).value as String?,
    };
    expect(fields['latitude'], '-6.362829');
    expect(fields['longitude'], '106.828655');
  });

  test('skipping the picker sends no coordinates at all', () async {
    api.on('POST', _bank, json: {'next_step': 'pending'});

    await cubit.registerBankSampah(bankRequest());

    final keys = ((api.last.body as dynamic).fields as List<dynamic>)
        .map((f) => (f as dynamic).key);
    expect(keys, isNot(contains('latitude')));
    expect(keys, isNot(contains('longitude')));
  });

  test('the directory entity parses saved coordinates or none', () {
    final withCoords = BankSampahDirectoryEntity.fromJson({
      'id': 'b1',
      'nama': 'Melati',
      'alamat': 'Jl',
      'kota': 'Depok',
      'latitude': '106.000000',
      'longitude': '-6.000000',
      'foto_logo': '',
    });
    expect(withCoords.lokasi, (latitude: 106.0, longitude: -6.0));

    final tanpa = BankSampahDirectoryEntity.fromJson({
      'id': 'b2',
      'nama': 'Kosong',
      'alamat': 'Jl',
      'kota': 'Depok',
      'foto_logo': '',
    });
    expect(tanpa.lokasi, isNull);
  });
}
