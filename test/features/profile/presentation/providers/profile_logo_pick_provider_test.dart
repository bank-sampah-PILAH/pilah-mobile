import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/states/profile_state.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../../../../support/profile_support.dart';

/// Builds a picker-style path with the *platform* separator.
///
/// A native picker hands back a platform path and `XFile.name` splits on the
/// platform separator, so a POSIX literal such as _picked('x.jpg') keeps its whole
/// directory as the filename on Windows and the assertions below read
/// _picked('x.jpg') where they mean 'x.jpg'.
String _picked(String name) => ['tmp', name].join(Platform.pathSeparator);

class _MockDataSource extends Mock implements ProfileRemoteDataSource {}

class _MockPicker extends Mock implements ImagePicker {}

class _MockCropper extends Mock implements ImageCropper {}

class _MockCroppedFile extends Mock implements CroppedFile {}

class _MockXFile extends Mock implements XFile {}

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
  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(ImageCompressFormat.jpg);
  });

  late _MockDataSource dataSource;
  late _MockPicker picker;
  late _MockCropper cropper;
  late TestProfileNotifier notifier;
  late ProviderContainer container;
  late ProviderSubscription<ProfileState> subscription;
  final croppedBytes = Uint8List.fromList([4, 5, 6]);
  Map<Symbol, dynamic> cropArgs = const {};

  void stubPick(String? path) {
    when(() => picker.pickImage(source: any(named: 'source')))
        .thenAnswer((_) async => path == null ? null : XFile(path));
  }

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
      if (path == null) return null;
      final file = _MockCroppedFile();
      when(() => file.path).thenReturn(path);
      when(() => file.readAsBytes()).thenAnswer((_) async => croppedBytes);
      return file;
    });
  }

  void stubPickAndCrop(String pickedPath, String croppedPath) {
    stubPick(pickedPath);
    stubCrop(croppedPath);
  }

  void stubUpdate({Exception? error}) {
    final call = when(() => dataSource.updateBankSampah(
          nama: any(named: 'nama'),
          alamat: any(named: 'alamat'),
          kota: any(named: 'kota'),
          noHpPic: any(named: 'noHpPic'),
          fotoLogoBytes: any(named: 'fotoLogoBytes'),
          fotoLogoFilename: any(named: 'fotoLogoFilename'),
        ));
    if (error != null) {
      call.thenThrow(error);
    } else {
      call.thenAnswer((_) async => _stored);
    }
  }

  setUp(() {
    dataSource = _MockDataSource();
    picker = _MockPicker();
    cropper = _MockCropper();
    notifier = TestProfileNotifier(dataSource, picker, cropper);
    container = ProviderContainer(
      overrides: [profileProvider.overrideWith(() => notifier)],
    );
    subscription = container.listen(profileProvider, (_, __) {});
  });
  tearDown(() {
    subscription.close();
    container.dispose();
  });

  group('pickLogo', () {
    test('uses browser bytes without launching the native cropper', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => picker.pickImage(source: any(named: 'source'))).thenAnswer(
        (_) async => XFile.fromData(bytes,
            path: 'bank-logo.png',
            name: 'bank-logo.png',
            mimeType: 'image/png'),
      );
      final webNotifier =
          TestProfileNotifier(dataSource, picker, cropper, isWeb: true);
      final webContainer = ProviderContainer(
        overrides: [profileProvider.overrideWith(() => webNotifier)],
      );
      final webSubscription = webContainer.listen(profileProvider, (_, __) {});
      addTearDown(() {
        webSubscription.close();
        webContainer.dispose();
      });

      await webNotifier.pickLogo();

      expect(webNotifier.state.selectedLogoBytes, bytes);
      expect(webNotifier.state.selectedLogoFilename, 'bank-logo.png');
      verifyZeroInteractions(cropper);
    });

    test('closing during a browser read does not emit after disposal',
        () async {
      final read = Completer<Uint8List>();
      final image = _MockXFile();
      when(() => image.name).thenReturn('logo.png');
      when(() => image.readAsBytes()).thenAnswer((_) => read.future);
      when(() => picker.pickImage(source: any(named: 'source')))
          .thenAnswer((_) async => image);
      final webNotifier =
          TestProfileNotifier(dataSource, picker, cropper, isWeb: true);
      final webContainer = ProviderContainer(
        overrides: [profileProvider.overrideWith(() => webNotifier)],
      );
      final webSubscription = webContainer.listen(profileProvider, (_, __) {});
      final picking = webNotifier.pickLogo();
      await Future<void>.delayed(Duration.zero);
      webSubscription.close();
      webContainer.dispose();
      read.complete(Uint8List.fromList([1, 2, 3]));

      await expectLater(picking, completes);
    });

    test('holds cropped bytes and filename, not the gallery original',
        () async {
      stubPickAndCrop(_picked('picked.heic'), _picked('image_cropper_1.jpg'));

      await notifier.pickLogo();

      expect(notifier.state.selectedLogoBytes, [4, 5, 6]);
      expect(notifier.state.selectedLogoFilename, 'image_cropper_1.jpg');
    });

    test('reads from the gallery, not the camera', () async {
      stubPickAndCrop(_picked('picked.jpg'), _picked('cropped.jpg'));

      await notifier.pickLogo();

      expect(
          verify(() => picker.pickImage(source: captureAny(named: 'source')))
              .captured
              .single,
          ImageSource.gallery);
    });

    test('crops square and bounded with the native JPEG conversion', () async {
      stubPickAndCrop(_picked('picked.heic'), _picked('cropped.jpg'));

      await notifier.pickLogo();

      expect(cropArgs[#sourcePath], _picked('picked.heic'));
      expect([cropArgs[#maxWidth], cropArgs[#maxHeight]], [1024, 1024]);
      final ratio = cropArgs[#aspectRatio] as CropAspectRatio;
      expect([ratio.ratioX, ratio.ratioY], [1.0, 1.0]);
      expect(cropArgs[#compressFormat], ImageCompressFormat.jpg);
      expect(cropArgs[#compressQuality], 70);
    });

    test('does not open the cropper when the gallery is cancelled', () async {
      stubPick(null);

      await notifier.pickLogo();

      verifyZeroInteractions(cropper);
      expect(notifier.state.selectedLogoBytes, isNull);
    });

    test('a cancelled pick keeps the logo already chosen', () async {
      stubPickAndCrop(_picked('first.jpg'), _picked('first-cropped.jpg'));
      await notifier.pickLogo();
      stubPick(null);

      await notifier.pickLogo();

      expect(notifier.state.selectedLogoBytes, croppedBytes);
      expect(notifier.state.selectedLogoFilename, 'first-cropped.jpg');
    });

    test('a cancelled crop keeps the logo already chosen', () async {
      stubPickAndCrop(_picked('first.jpg'), _picked('first-cropped.jpg'));
      await notifier.pickLogo();
      stubPick(_picked('second.jpg'));
      stubCrop(null);

      await notifier.pickLogo();

      expect(notifier.state.selectedLogoBytes, croppedBytes);
      expect(notifier.state.selectedLogoFilename, 'first-cropped.jpg');
    });
  });

  group('updateBankSampah', () {
    test('sends browser bytes and clears the selection on success', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      notifier.setStateForTest(notifier.state.copyWith(
          selectedLogoBytes: bytes, selectedLogoFilename: 'bank-logo.png'));
      stubUpdate();

      expect(
          await notifier.updateBankSampah(
              nama: 'Bank Sampah BTH',
              alamat: 'Kel. Kukusan',
              noHpPic: '081234567890'),
          isNull);

      verify(() => dataSource.updateBankSampah(
          nama: 'Bank Sampah BTH',
          alamat: 'Kel. Kukusan',
          kota: null,
          noHpPic: '081234567890',
          fotoLogoBytes: bytes,
          fotoLogoFilename: 'bank-logo.png')).called(1);
      expect(notifier.state.selectedLogoBytes, isNull);
      expect(notifier.state.selectedLogoFilename, isNull);
    });

    test('sends native cropped bytes along with the text fields', () async {
      notifier.setStateForTest(notifier.state.copyWith(bankSampah: _stored));
      stubPickAndCrop(_picked('picked.heic'), _picked('cropped.jpg'));
      await notifier.pickLogo();
      stubUpdate();

      await notifier.updateBankSampah(
          nama: 'Bank Sampah BTH',
          alamat: 'Kel. Kukusan',
          noHpPic: '081234567890');

      verify(() => dataSource.updateBankSampah(
          nama: 'Bank Sampah BTH',
          alamat: 'Kel. Kukusan',
          kota: 'Depok',
          noHpPic: '081234567890',
          fotoLogoBytes: croppedBytes,
          fotoLogoFilename: 'cropped.jpg')).called(1);
      expect(notifier.state.selectedLogoBytes, isNull);
      expect(notifier.state.selectedLogoFilename, isNull);
    });

    test('a failed save keeps the photo and can retry without re-picking',
        () async {
      notifier.setStateForTest(notifier.state.copyWith(
          bankSampah: _stored,
          selectedLogoBytes: croppedBytes,
          selectedLogoFilename: 'cropped.jpg'));
      stubUpdate(
          error: DioException(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        response: Response(
            requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
            statusCode: 422,
            data: const {
              'errors': {
                'foto_logo': ['Foto logo harus berformat JPG, JPEG, atau PNG']
              }
            }),
        type: DioExceptionType.badResponse,
      ));

      final error =
          await notifier.updateBankSampah(nama: 'n', alamat: 'a', noHpPic: 'p');

      expect(error?.displayMessage,
          'Foto logo harus berformat JPG, JPEG, atau PNG');
      expect(notifier.state.selectedLogoBytes, croppedBytes);
      expect(notifier.state.selectedLogoFilename, 'cropped.jpg');
      stubUpdate();
      expect(
          await notifier.updateBankSampah(nama: 'n', alamat: 'a', noHpPic: 'p'),
          isNull);
      expect(notifier.state.selectedLogoBytes, isNull);
    });
  });
}
