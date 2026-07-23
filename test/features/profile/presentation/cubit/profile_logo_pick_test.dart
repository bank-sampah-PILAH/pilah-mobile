import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';

class _MockDataSource extends Mock implements ProfileRemoteDataSource {}

class _MockPicker extends Mock implements ImagePicker {}

class _MockCropper extends Mock implements ImageCropper {}

const _stored = BankSampahProfile(
  id: 'bank-1',
  nama: 'Bank Sampah BTH',
  alamat: 'Kel. Kukusan',
  kota: 'Depok',
  noHpPic: '+6281234567890',
  status: 'active',
  fotoLogo: 'https://api.pilah.test/media/bank_sampah/logo/old.png',
);

void main() {
  // Matchers need a real value of each non-nullable type they stand in for.
  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(ImageCompressFormat.jpg);
  });

  late _MockDataSource dataSource;
  late _MockPicker picker;
  late _MockCropper cropper;
  late ProfileCubit cubit;

  /// Stubs the gallery to return [path], or to be cancelled when null.
  void stubPick(String? path) {
    when(() => picker.pickImage(source: any(named: 'source')))
        .thenAnswer((_) async => path == null ? null : XFile(path));
  }

  /// The arguments the cropper was last invoked with, keyed by parameter name.
  ///
  /// Read from the invocation rather than `verify(...).captured`, whose order
  /// for named parameters is not the signature's and so silently pairs the
  /// wrong assertion with the wrong argument.
  Map<Symbol, dynamic> cropArgs = const {};

  /// Stubs the cropper to return [path], or to be cancelled when null.
  void stubCrop(String? path) {
    when(() => cropper.cropImage(
          sourcePath: any(named: 'sourcePath'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          aspectRatio: any(named: 'aspectRatio'),
          compressFormat: any(named: 'compressFormat'),
          compressQuality: any(named: 'compressQuality'),
          uiSettings: any(named: 'uiSettings'),
        )).thenAnswer((invocation) async {
      cropArgs = invocation.namedArguments;
      return path == null ? null : CroppedFile(path);
    });
  }

  /// The ordinary path: a gallery pick followed by a completed crop.
  void stubPickAndCrop(String pickedPath, String croppedPath) {
    stubPick(pickedPath);
    stubCrop(croppedPath);
  }

  setUp(() {
    dataSource = _MockDataSource();
    picker = _MockPicker();
    cropper = _MockCropper();
    cubit = ProfileCubit(dataSource, picker, cropper);
  });

  tearDown(() => cubit.close());

  group('pickLogo', () {
    test('holds the cropped file, not the one straight out of the gallery',
        () async {
      stubPickAndCrop('/tmp/picked.heic', '/tmp/image_cropper_1.jpg');

      await cubit.pickLogo();

      expect(
        cubit.state.selectedLogoFile?.path,
        '/tmp/image_cropper_1.jpg',
        reason: 'the gallery original is the cropper input; uploading it would '
            'put an uncropped image behind a circular avatar',
      );
    });

    test('reads from the gallery, not the camera', () async {
      stubPickAndCrop('/tmp/picked.jpg', '/tmp/cropped.jpg');

      await cubit.pickLogo();

      final source = verify(() => picker.pickImage(
            source: captureAny(named: 'source'),
          )).captured.single;
      expect(source, ImageSource.gallery);
    });

    test('crops the gallery file, square and bounded', () async {
      stubPickAndCrop('/tmp/picked.jpg', '/tmp/cropped.jpg');

      await cubit.pickLogo();

      expect(cropArgs[#sourcePath], '/tmp/picked.jpg');
      expect([cropArgs[#maxWidth], cropArgs[#maxHeight]], [1024, 1024]);

      final ratio = cropArgs[#aspectRatio] as CropAspectRatio;
      expect(
        [ratio.ratioX, ratio.ratioY],
        [1.0, 1.0],
        reason: 'a locked 1:1 is what keeps the avatar from cropping the '
            'result a second time',
      );
      // JPG regardless of what the gallery handed over, so an iOS HEIC never
      // reaches an API that accepts only JPG and PNG.
      expect(cropArgs[#compressFormat], ImageCompressFormat.jpg);
      expect(cropArgs[#compressQuality], 70);
    });

    test('does not open the cropper when the gallery is cancelled', () async {
      stubPick(null);
      stubCrop('/tmp/cropped.jpg');

      await cubit.pickLogo();

      verifyNever(() => cropper.cropImage(
            sourcePath: any(named: 'sourcePath'),
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            aspectRatio: any(named: 'aspectRatio'),
            compressFormat: any(named: 'compressFormat'),
            compressQuality: any(named: 'compressQuality'),
            uiSettings: any(named: 'uiSettings'),
          ));
      expect(cubit.state.selectedLogoFile, isNull);
    });

    test('a cancelled pick keeps the logo already chosen', () async {
      stubPickAndCrop('/tmp/first.jpg', '/tmp/first-cropped.jpg');
      await cubit.pickLogo();
      stubPick(null);

      await cubit.pickLogo();

      expect(
        cubit.state.selectedLogoFile?.path,
        '/tmp/first-cropped.jpg',
        reason: 'backing out of the gallery is not a request to undo',
      );
    });

    test('a cancelled crop keeps the logo already chosen', () async {
      stubPickAndCrop('/tmp/first.jpg', '/tmp/first-cropped.jpg');
      await cubit.pickLogo();
      stubPickAndCrop('/tmp/second.jpg', '/tmp/ignored.jpg');
      stubCrop(null);

      await cubit.pickLogo();

      expect(
        cubit.state.selectedLogoFile?.path,
        '/tmp/first-cropped.jpg',
        reason: 'abandoning the crop discards that attempt only — it must not '
            'clear a logo the user settled on earlier',
      );
    });
  });

  group('updateBankSampah', () {
    test('sends the pending logo along with the text fields', () async {
      cubit.emit(cubit.state.copyWith(
        bankSampah: _stored,
        selectedLogoFile: File('/tmp/new-logo.png'),
      ));
      when(() => dataSource.updateBankSampah(
            nama: any(named: 'nama'),
            alamat: any(named: 'alamat'),
            kota: any(named: 'kota'),
            noHpPic: any(named: 'noHpPic'),
            fotoLogoPath: any(named: 'fotoLogoPath'),
          )).thenAnswer((_) async => _stored);

      await cubit.updateBankSampah(
        nama: 'Bank Sampah BTH',
        alamat: 'Kel. Kukusan',
        noHpPic: '081234567890',
      );

      verify(() => dataSource.updateBankSampah(
            nama: 'Bank Sampah BTH',
            alamat: 'Kel. Kukusan',
            kota: 'Depok',
            noHpPic: '081234567890',
            fotoLogoPath: '/tmp/new-logo.png',
          )).called(1);
    });

    test('releases the file once the upload lands', () async {
      cubit.emit(cubit.state.copyWith(
        bankSampah: _stored,
        selectedLogoFile: File('/tmp/new-logo.png'),
      ));
      when(() => dataSource.updateBankSampah(
            nama: any(named: 'nama'),
            alamat: any(named: 'alamat'),
            kota: any(named: 'kota'),
            noHpPic: any(named: 'noHpPic'),
            fotoLogoPath: any(named: 'fotoLogoPath'),
          )).thenAnswer((_) async => _stored);

      await cubit.updateBankSampah(
        nama: 'n',
        alamat: 'a',
        noHpPic: 'p',
      );

      expect(
        cubit.state.selectedLogoFile,
        isNull,
        reason: 'the saved logo is on the entity now; keeping the local file '
            'would preview something already stored',
      );
    });

    test('keeps the file when the upload fails, so a retry needs no re-pick',
        () async {
      cubit.emit(cubit.state.copyWith(
        bankSampah: _stored,
        selectedLogoFile: File('/tmp/new-logo.png'),
      ));
      when(() => dataSource.updateBankSampah(
            nama: any(named: 'nama'),
            alamat: any(named: 'alamat'),
            kota: any(named: 'kota'),
            noHpPic: any(named: 'noHpPic'),
            fotoLogoPath: any(named: 'fotoLogoPath'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
          statusCode: 422,
          data: const {
            'errors': {
              'foto_logo': ['Foto logo harus berformat JPG, JPEG, atau PNG']
            }
          },
        ),
        type: DioExceptionType.badResponse,
      ));

      final error = await cubit.updateBankSampah(
        nama: 'n',
        alamat: 'a',
        noHpPic: 'p',
      );

      expect(cubit.state.selectedLogoFile?.path, '/tmp/new-logo.png');
      expect(
        error?.displayMessage,
        'Foto logo harus berformat JPG, JPEG, atau PNG',
        reason: 'the backend names what it refused; a generic failure would '
            'leave the user re-picking the same rejected file',
      );
    });
  });
}
