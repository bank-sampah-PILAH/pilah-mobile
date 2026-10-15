import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';

import '../../../support/profile_support.dart';
import '../../../support/stub_api.dart';

class _Picker extends Mock implements ImagePicker {}

class _Cropper extends Mock implements ImageCropper {}

void main() {
  test('browser logo selection uploads exact bytes and retries without re-pick',
      () async {
    final api = StubApi();
    final picker = _Picker();
    final cropper = _Cropper();
    final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
    when(() => picker.pickImage(source: ImageSource.gallery)).thenAnswer(
      (_) async => XFile.fromData(bytes,
          path: 'blob:http://localhost/logo.png',
          name: 'logo.png',
          mimeType: 'image/png'),
    );
    final cubit = ProfileCubit(
        ProfileRemoteDataSourceImpl(api.network), picker, cropper,
        isWeb: true);
    addTearDown(cubit.close);
    api.on('PUT', '/api/v1/bank-sampah/me',
        status: 413, json: {'error': 'Foto terlalu besar'});

    await cubit.pickLogo();
    expect(cubit.state.selectedLogoBytes, bytes);
    expect(cubit.state.selectedLogoFilename, 'logo.png');
    final error = await cubit.updateBankSampah(
        nama: 'Bank Sampah BTH',
        alamat: 'Kel. Kukusan',
        noHpPic: '81234567890');
    expect(error?.displayMessage, 'Foto terlalu besar');
    expect(cubit.state.selectedLogoBytes, bytes);

    api.on('PUT', '/api/v1/bank-sampah/me',
        json: bankJson(logo: '/media/logo.png'));
    expect(
        await cubit.updateBankSampah(
            nama: 'Bank Sampah BTH',
            alamat: 'Kel. Kukusan',
            noHpPic: '81234567890'),
        isNull);

    for (final request in api.requests) {
      final form = request.body as FormData;
      expect(Map.fromEntries(form.fields), {
        'nama': 'Bank Sampah BTH',
        'alamat': 'Kel. Kukusan',
        'no_hp_pic': '81234567890'
      });
      expect(form.files.single.key, 'foto_logo');
      final photo = form.files.single.value;
      expect(photo.filename, 'logo.png');
      expect(await photo.clone().finalize().expand((chunk) => chunk).toList(),
          bytes);
      expect(request.headers[Headers.contentTypeHeader],
          startsWith('multipart/form-data; boundary='));
    }
    verify(() => picker.pickImage(source: ImageSource.gallery)).called(1);
    verifyZeroInteractions(cropper);
    expect(cubit.state.selectedLogoBytes, isNull);
    expect(cubit.state.selectedLogoFilename, isNull);
    expect(cubit.state.bankSampah?.fotoLogo, 'http://api.test/media/logo.png');

    await cubit.updateBankSampah(
        nama: 'Bank Sampah BTH',
        alamat: 'Kel. Kukusan',
        noHpPic: '81234567890');
    expect((api.last.body as FormData).files, isEmpty,
        reason: 'a later text-only save must not clear or re-upload the logo');
  });
}
