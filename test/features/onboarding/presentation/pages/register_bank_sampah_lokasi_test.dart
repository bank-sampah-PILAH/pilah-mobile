import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/map/data/datasources/koordinat_remote_data_source.dart';
import 'package:pilah_mobile/features/map/domain/entities/hasil_koordinat.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/onboarding_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

class _FakeKoordinatSource extends Mock implements KoordinatRemoteDataSource {}

class _FakeLocationService extends Mock implements LocationService {}

/// PIL-326 optional coordinate section on bank registration: the map door, and
/// the three doors that keep working when the tiles do not.
void main() {
  late StubApi api;
  late ProviderContainer onboarding;
  late TestAuthenticationNotifier auth;
  late _FakeKoordinatSource koordinat;
  late _FakeLocationService location;

  setUp(() {
    api = StubApi();
    onboarding = buildOnboardingContainer(buildOnboardingDataSource(api));
    auth = authNotifierIn(AuthenticationInitial());
    koordinat = _FakeKoordinatSource();
    location = _FakeLocationService();
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    di.allowReassignment = true;
    di.registerSingleton<KoordinatRemoteDataSource>(koordinat);
    di.registerSingleton<LocationService>(location);
    TileHealth.instance.pulihkan();
  });

  tearDown(() async {
    await di.unregister<KoordinatRemoteDataSource>();
    await di.unregister<LocationService>();
    TileHealth.instance.pulihkan();
    onboarding.dispose();
  });

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      UncontrolledProviderScope(
        container: onboarding,
        child: withAuthenticationProvider(
          auth,
          RegisterBankSampahScreen(
            // No tiles are fetched inside `flutter test`.
            tileLayerBuilder: () => const SizedBox.shrink(),
          ),
        ),
      ),
      size: const Size(800, 2600),
    );
    await tester.pumpAndSettle();
  }

  /// Field order on the form: bank name, address, PIC phone.
  Future<void> isiAlamat(WidgetTester tester, String alamat) async {
    await tester.enterText(find.byType(TextFormField).at(1), alamat);
    await tester.pump();
  }

  HasilKoordinat hasil(
          {double lat = -6.37, double lng = 106.82, String? alamat}) =>
      HasilKoordinat(
        latitude: lat,
        longitude: lng,
        sumber: 'geocode',
        alamatHasil: alamat,
      );

  testWidgets('a picked point shows its coordinates and can be removed',
      (tester) async {
    await open(tester);

    expect(find.text('Pilih di peta'), findsOneWidget);

    await tester.tap(find.text('Pilih di peta'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan Lokasi'), findsOneWidget);

    await tester.tap(find.text('Simpan Lokasi'));
    await tester.pumpAndSettle();

    // The picker returns the coordinate pair; registration shows it and offers
    // a way to drop it again.
    expect(find.text('Pilih di peta'), findsNothing);
    expect(find.textContaining(','), findsWidgets);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Pilih di peta'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('Lokasi saya takes the device fix without a map', (tester) async {
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -6.371, longitude: 106.828));
    await open(tester);

    await tester.tap(find.byKey(const Key('lokasi_pakai_gps')));
    await tester.pumpAndSettle();

    expect(find.text('-6.371000, 106.828000'), findsOneWidget);
    // No geocoded address came with a device fix.
    expect(find.byKey(const Key('lokasi_alamat_hasil')), findsNothing);
  });

  testWidgets('a device with no fix leaves the field empty', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('lokasi_pakai_gps')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih di peta'), findsOneWidget);
  });

  testWidgets('Dari alamat needs the address typed first', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('lokasi_dari_alamat')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih di peta'), findsOneWidget);
    verifyNever(() => koordinat.dariAlamat(alamat: any(named: 'alamat')));
  });

  testWidgets('Dari alamat resolves the typed address and shows the match',
      (tester) async {
    when(() => koordinat.dariAlamat(alamat: 'Jl. Margonda 5'))
        .thenAnswer((_) async => hasil(alamat: 'Fasilkom UI, Depok'));
    await open(tester);
    await isiAlamat(tester, 'Jl. Margonda 5');

    await tester.tap(find.byKey(const Key('lokasi_dari_alamat')));
    await tester.pumpAndSettle();

    expect(find.text('-6.370000, 106.820000'), findsOneWidget);
    expect(find.byKey(const Key('lokasi_alamat_hasil')), findsOneWidget);
    expect(find.text('Fasilkom UI, Depok'), findsOneWidget);
  });

  testWidgets('a failed lookup keeps the form as it was', (tester) async {
    when(() => koordinat.dariAlamat(alamat: any(named: 'alamat')))
        .thenThrow(Exception('geocoder down'));
    await open(tester);
    await isiAlamat(tester, 'Jl. Margonda 5');

    await tester.tap(find.byKey(const Key('lokasi_dari_alamat')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih di peta'), findsOneWidget);
  });

  testWidgets('Tempel tautan reads a pasted Google Maps link', (tester) async {
    when(() => koordinat.dariTautan('https://maps.app.goo.gl/abc'))
        .thenAnswer((_) async => const HasilKoordinat(
              latitude: -6.369774,
              longitude: 106.826916,
              sumber: 'tautan',
            ));
    await open(tester);

    await tester.tap(find.byKey(const Key('lokasi_dari_tautan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tautan_maps_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('tautan_maps_field')),
      'https://maps.app.goo.gl/abc',
    );
    await tester.tap(find.text('Ambil koordinat'));
    await tester.pumpAndSettle();

    expect(find.text('-6.369774, 106.826916'), findsOneWidget);
  });

  testWidgets('cancelling the link dialog changes nothing', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('lokasi_dari_tautan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih di peta'), findsOneWidget);
    verifyNever(() => koordinat.dariTautan(any()));
  });

  testWidgets('with tiles down the section says the three doors still work',
      (tester) async {
    for (var i = 0; i < TileHealth.instance.ambang; i++) {
      TileHealth.instance.catatGalat();
    }

    await open(tester);

    expect(find.byKey(const Key('lokasi_peta_galat')), findsOneWidget);
    expect(find.byKey(const Key('lokasi_pakai_gps')), findsOneWidget);
    expect(find.byKey(const Key('lokasi_dari_alamat')), findsOneWidget);
    expect(find.byKey(const Key('lokasi_dari_tautan')), findsOneWidget);
  });
}
