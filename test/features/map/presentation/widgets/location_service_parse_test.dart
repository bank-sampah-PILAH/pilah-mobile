import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeGeolocator extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

late FakeGeolocator geolocator;

void main() {
  group('parseLokasi', () {
    test('a complete pair parses with full precision', () {
      final lokasi = parseLokasi('-6.362829', '106.828655');
      expect(lokasi, isNotNull);
      expect(lokasi!.latitude, -6.362829);
      expect(lokasi.longitude, 106.828655);
    });

    test('null or empty boundaries degrade to null', () {
      expect(parseLokasi(null, '106.0'), isNull);
      expect(parseLokasi('-6.0', null), isNull);
      expect(parseLokasi(null, null), isNull);
      expect(parseLokasi('', ''), isNull);
    });

    test('a half-written pair is no location, not a crash', () {
      expect(parseLokasi('-6.0', 'bukan-angka'), isNull);
      expect(parseLokasi('-6.0', ''), isNull);
      // An unbackfilled bank serializes nothing; non-numeric strings from a
      // hostile payload must behave the same.
      expect(parseLokasi('abc', '106.0'), isNull);
    });
  });

  group('currentLocation against the geolocator platform', () {
    setUp(() {
      geolocator = FakeGeolocator();
      GeolocatorPlatform.instance = geolocator;
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      registerFallbackValue(LocationSettings());
      when(() => geolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer((_) async => Position(
            latitude: -6.3,
            longitude: 106.8,
            timestamp: DateTime(2026),
            accuracy: 5,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          ));
    });

    test('granted permission returns the fix', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      expect(await LocationService().currentLocation(), isNotNull);
    });

    test('denied then refused degrades to null', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(() => geolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      expect(await LocationService().currentLocation(), isNull);
    });

    test('deniedForever and an offline service degrade to null', () async {
      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);
      expect(await LocationService().currentLocation(), isNull);

      when(() => geolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(() => geolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);
      expect(await LocationService().currentLocation(), isNull);
    });

    test('a platform-channel explosion degrades to null', () async {
      when(() => geolocator.checkPermission()).thenThrow(Exception('boom'));
      expect(await LocationService().currentLocation(), isNull);
    });
  });
}
