import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';

import 'stub_api.dart';

class MockImagePicker extends Mock implements ImagePicker {}

class MockImageCropper extends Mock implements ImageCropper {}

class TestProfileNotifier extends ProfileNotifier {
  TestProfileNotifier(
    super.dataSource,
    super.picker,
    super.cropper, {
    super.isWeb,
  });

  void setStateForTest(ProfileState value) => state = value;
}

/// A real [ProfileNotifier] with HTTP stubbed and media plugins mocked.
TestProfileNotifier buildProfileNotifier(
  StubApi api, {
  ImagePicker? picker,
  ImageCropper? cropper,
}) =>
    TestProfileNotifier(
      ProfileRemoteDataSourceImpl(api.network),
      picker ?? MockImagePicker(),
      cropper ?? MockImageCropper(),
    );

/// Stubs the three endpoints a successful profile load reads.
void stubProfile(
  StubApi api, {
  Map<String, dynamic>? bank,
  Object? wa,
  Object? team,
}) {
  api.on('GET', '/api/v1/bank-sampah/me', json: bank ?? bankJson());
  api.on('GET', '/api/v1/pengaturan/wa-template',
      json: wa ??
          {
            'template': 'Halo {nama}',
            'preview_contoh': 'Halo Budi',
            'variabel_tersedia': ['{Nama}', '{Total}'],
          });
  api.on('GET', '/api/v1/team',
      json: team ??
          {
            'members': [
              {
                'id': 'm1',
                'nama': 'Siti',
                'email': 'siti@x.test',
                'is_primary_pengelola': true,
                'is_current_user': true,
              },
              {
                'id': 'm2',
                'nama': 'Andi',
                'email': 'andi@x.test',
              },
            ],
          });
}

Map<String, dynamic> bankJson({Object? logo}) => {
      'id': 'bank-1',
      'nama': 'Bank Sampah BTH',
      'alamat': 'Kel. Kukusan',
      'kota': 'Depok',
      'no_hp_pic': '+6281234567890',
      'status': 'active',
      if (logo != null) 'foto_logo': logo,
    };
