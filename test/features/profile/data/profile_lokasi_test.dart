import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart';

class _MockNetworkService extends Mock implements NetworkService {}

class _FakeFormData extends Fake implements FormData {}

/// Coordinates arrive the way DRF serialises the DecimalFields — strings that
/// keep trailing zeros. Round-tripping through `double` must keep working.
Map<String, dynamic> _bankJson({Object? latitude, Object? longitude}) => {
      'id': 'bank-1',
      'nama': 'Bank Sampah BTH',
      'alamat': 'Kel. Kukusan',
      'kota': 'Depok',
      'no_hp_pic': '+6281234567890',
      'status': 'active',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

void main() {
  setUpAll(() => registerFallbackValue(_FakeFormData()));

  late _MockNetworkService network;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    network = _MockNetworkService();
    dataSource = ProfileRemoteDataSourceImpl(network);
  });

  group('getBankSampah parses the saved location', () {
    test('both boundaries present parse into a pair', () async {
      final response = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        data: _bankJson(latitude: '-6.362829', longitude: '106.828655'),
      );
      when(() => network.get(any())).thenAnswer((_) async => response);

      final bank = await dataSource.getBankSampah();

      expect(bank.lokasi, (latitude: -6.362829, longitude: 106.828655));
    });

    test('trailing zeros from the decimal field still parse', () async {
      final response = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        data: _bankJson(latitude: '106.000000', longitude: '0.000000'),
      );
      when(() => network.get(any())).thenAnswer((_) async => response);

      final bank = await dataSource.getBankSampah();

      expect(bank.lokasi, (latitude: 106.0, longitude: 0.0));
    });

    test('a bank without coordinates maps to null, not an error', () async {
      final response = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        data: _bankJson(),
      );
      when(() => network.get(any())).thenAnswer((_) async => response);

      final bank = await dataSource.getBankSampah();

      expect(bank.lokasi, isNull);
    });

    test('a half-written pair is no location at all', () async {
      final response = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/bank-sampah/me'),
        data: _bankJson(latitude: '-6.3'),
      );
      when(() => network.get(any())).thenAnswer((_) async => response);

      final bank = await dataSource.getBankSampah();

      expect(bank.lokasi, isNull);
    });
  });

  group('updateBankSampah sends the location', () {
    FormData? sent;

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
    });

    test(
        'carries the picked location under latitude/longitude '
        '(strings, multipart-safe)', () async {
      stubPut(_bankJson());

      await dataSource.updateBankSampah(
        nama: 'B',
        alamat: 'Kel. Kukusan',
        noHpPic: '081234567890',
        lokasi: (latitude: -6.362829123, longitude: 106.8),
      );

      final fields = {for (final f in sent!.fields) f.key: f.value};
      expect(fields['latitude'], '-6.362829');
      expect(fields['longitude'], '106.800000');
    });

    test('omitting the location leaves the stored one untouched', () async {
      stubPut(_bankJson());

      await dataSource.updateBankSampah(
        nama: 'B',
        alamat: 'Kel. Kukusan',
        noHpPic: '081234567890',
      );

      final keys = sent!.fields.map((f) => f.key);
      expect(keys, isNot(contains('latitude')));
      expect(keys, isNot(contains('longitude')));
    });
  });
}
