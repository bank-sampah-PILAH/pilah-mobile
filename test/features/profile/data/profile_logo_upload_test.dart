import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';

class _MockNetworkService extends Mock implements NetworkService {}

class _FakeFormData extends Fake implements FormData {}

class _StubEnvironment implements AppEnvironment {
  @override
  final String baseUrl;

  const _StubEnvironment(this.baseUrl);
}

/// The shape `PUT /bank-sampah/me` answers with, so the mapper has something
/// realistic to read. [fotoLogo] is placed exactly as DRF serialises the
/// FileField — absent when nothing was ever uploaded.
Map<String, dynamic> _bankJson({Object? fotoLogo}) => {
      'id': 'bank-1',
      'nama': 'Bank Sampah BTH',
      'alamat': 'Kel. Kukusan',
      'kota': 'Depok',
      'no_hp_pic': '+6281234567890',
      'status': 'active',
      if (fotoLogo != null) 'foto_logo': fotoLogo,
    };

void main() {
  setUpAll(() => registerFallbackValue(_FakeFormData()));

  late _MockNetworkService network;
  late ProfileRemoteDataSourceImpl dataSource;
  late FormData? sent;

  /// Answers the next `putMultipart` with [json], keeping whatever FormData it
  /// was handed so the request itself can be asserted on.
  void stubPut(Map<String, dynamic> json) {
    when(() => network.putMultipart(any(), formData: any(named: 'formData')))
        .thenAnswer((invocation) async {
      sent = invocation.namedArguments[#formData] as FormData;
      return Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        data: json,
      );
    });
  }

  setUp(() {
    sent = null;
    network = _MockNetworkService();
    when(() => network.environment)
        .thenReturn(const _StubEnvironment('https://api.pilah.test'));
    dataSource = ProfileRemoteDataSourceImpl(network);
  });

  group('updateBankSampah', () {
    test('sends the editable fields as multipart, with no logo attached',
        (() async {
      stubPut(_bankJson());

      await dataSource.updateBankSampah(
        nama: 'Bank Sampah BTH',
        alamat: 'Kel. Kukusan',
        kota: 'Depok',
        noHpPic: '081234567890',
      );

      final fields = {for (final f in sent!.fields) f.key: f.value};
      expect(fields, {
        'nama': 'Bank Sampah BTH',
        'alamat': 'Kel. Kukusan',
        'kota': 'Depok',
        'no_hp_pic': '081234567890',
      });
      expect(
        sent!.files,
        isEmpty,
        reason: 'the endpoint patches partially, so an empty foto_logo would '
            'clear a logo the user never touched',
      );
    }));

    test('attaches the picked file under foto_logo', () async {
      final file = File('${Directory.systemTemp.createTempSync().path}/logo.png')
        ..writeAsBytesSync(List<int>.filled(64, 7));
      addTearDown(() => file.parent.deleteSync(recursive: true));
      stubPut(_bankJson(fotoLogo: '/media/bank_sampah/logo/logo.png'));

      await dataSource.updateBankSampah(
        nama: 'Bank Sampah BTH',
        alamat: 'Kel. Kukusan',
        noHpPic: '081234567890',
        fotoLogoPath: file.path,
      );

      expect(sent!.files.map((f) => f.key), ['foto_logo']);
      expect(sent!.files.single.value.filename, 'logo.png');
    });

    test('goes through putMultipart, never the JSON put', () async {
      stubPut(_bankJson());

      await dataSource.updateBankSampah(
        nama: 'Bank Sampah BTH',
        alamat: 'Kel. Kukusan',
        noHpPic: '081234567890',
      );

      // put() pins Content-Type to application/json, which would strip the
      // multipart boundary and leave the server unable to read the body.
      verifyNever(() => network.put(any(),
          data: any(named: 'data'), formData: any(named: 'formData')));
      verify(() => network.putMultipart(any(), formData: any(named: 'formData')))
          .called(1);
    });
  });

  group('foto_logo mapping', () {
    test('resolves the relative path local file storage returns', () async {
      stubPut(_bankJson(fotoLogo: '/media/bank_sampah/logo/logo.png'));

      final bank = await dataSource.updateBankSampah(
        nama: 'n',
        alamat: 'a',
        noHpPic: 'p',
      );

      expect(bank.fotoLogo,
          'https://api.pilah.test/media/bank_sampah/logo/logo.png');
    });

    test('leaves the absolute URL a bucket returns alone', () async {
      const url =
          'https://storage.googleapis.com/pilah/media/bank_sampah/logo/l.png';
      stubPut(_bankJson(fotoLogo: url));

      final bank = await dataSource.updateBankSampah(
        nama: 'n',
        alamat: 'a',
        noHpPic: 'p',
      );

      expect(bank.fotoLogo, url);
    });

    test('is null when no logo has been uploaded', () async {
      stubPut(_bankJson());

      final bank = await dataSource.updateBankSampah(
        nama: 'n',
        alamat: 'a',
        noHpPic: 'p',
      );

      expect(
        bank.fotoLogo,
        isNull,
        reason: 'the avatar decides on null, so an empty string would read as '
            'a logo that exists and fails to load',
      );
    });

    test('treats the empty string a blank FileField serialises to as no logo',
        () async {
      stubPut(_bankJson(fotoLogo: ''));

      final bank = await dataSource.updateBankSampah(
        nama: 'n',
        alamat: 'a',
        noHpPic: 'p',
      );

      expect(bank.fotoLogo, isNull);
    });
  });
}
