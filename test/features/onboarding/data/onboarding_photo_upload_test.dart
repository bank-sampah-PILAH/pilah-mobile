import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

import '../../../support/stub_api.dart';

void main() {
  test('registers with a browser-selected activity photo', () async {
    final api = StubApi();
    api.on('POST', '/api/v1/onboarding/bank-sampah',
        json: {'next_step': 'pending_approval'});
    final source = OnboardingRemoteDataSourceImpl(api.network);

    final bytes = Uint8List.fromList([1, 2, 3]);
    final result = await source.registerBankSampah(
      RegisterBankSampahRequest(
        nama: 'Bank Melati',
        alamat: 'Jl. Melati 1',
        noHpPic: '81234567890',
        fotoKegiatanBytes: bytes,
        fotoKegiatanFilename: 'kegiatan.png',
      ),
    );

    expect(result.nextStep, 'pending_approval');
    final form = api.last.body as FormData;
    expect(Map.fromEntries(form.fields), {
      'nama': 'Bank Melati',
      'alamat': 'Jl. Melati 1',
      'no_hp_pic': '81234567890',
    });
    expect(form.files.single.key, 'foto_kegiatan');
    final photo = form.files.single.value;
    expect(photo.filename, 'kegiatan.png');
    expect(await photo.clone().finalize().expand((chunk) => chunk).toList(),
        bytes);
    expect(api.last.headers[Headers.contentTypeHeader],
        startsWith('multipart/form-data; boundary='));
  });
}
