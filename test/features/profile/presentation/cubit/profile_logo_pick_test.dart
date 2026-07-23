import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pilah_mobile/features/profile/domain/entities/profile_entities.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';

class _MockDataSource extends Mock implements ProfileRemoteDataSource {}

class _MockPicker extends Mock implements ImagePicker {}

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
  // `any(named: 'source')` needs a real ImageSource to hand the matcher.
  setUpAll(() => registerFallbackValue(ImageSource.gallery));

  late _MockDataSource dataSource;
  late _MockPicker picker;
  late ProfileCubit cubit;

  /// Stubs the gallery to return [path], or to be cancelled when null.
  void stubPick(String? path) {
    when(() => picker.pickImage(
          source: any(named: 'source'),
          imageQuality: any(named: 'imageQuality'),
          maxWidth: any(named: 'maxWidth'),
        )).thenAnswer((_) async => path == null ? null : XFile(path));
  }

  setUp(() {
    dataSource = _MockDataSource();
    picker = _MockPicker();
    cubit = ProfileCubit(dataSource, picker);
  });

  tearDown(() => cubit.close());

  group('pickLogo', () {
    test('holds the chosen file so the avatar can preview it', () async {
      stubPick('/tmp/new-logo.png');

      await cubit.pickLogo();

      expect(cubit.state.selectedLogoFile?.path, '/tmp/new-logo.png');
    });

    test('reads from the gallery, not the camera', () async {
      stubPick('/tmp/new-logo.png');

      await cubit.pickLogo();

      final source = verify(() => picker.pickImage(
            source: captureAny(named: 'source'),
            imageQuality: any(named: 'imageQuality'),
            maxWidth: any(named: 'maxWidth'),
          )).captured.single;
      expect(source, ImageSource.gallery);
    });

    test('a cancelled pick keeps the logo already chosen', () async {
      stubPick('/tmp/first.png');
      await cubit.pickLogo();
      stubPick(null);

      await cubit.pickLogo();

      expect(
        cubit.state.selectedLogoFile?.path,
        '/tmp/first.png',
        reason: 'backing out of the gallery is not a request to undo',
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
