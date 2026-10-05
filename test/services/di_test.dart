import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

void main() {
  setUp(() => configureDependencies(environment: AppKey.devEnv));
  tearDown(() => di.reset());

  test('wires the nasabah repository on top of the generated graph', () {
    expect(di.isRegistered<NasabahRepository>(), isTrue);
  });

  test('provides one shared image picker and cropper', () {
    expect(di<ImagePicker>(), same(di<ImagePicker>()));
    expect(di<ImageCropper>(), same(di<ImageCropper>()));
  });
}
