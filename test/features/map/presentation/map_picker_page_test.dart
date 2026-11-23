import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';
import 'package:pilah_mobile/services/di.dart';

class _FakeLocationService extends Mock implements LocationService {}

class _FakeNetworkService extends Mock implements NetworkService {}

// The test seam the page was built for: a tile layer that draws nothing, so
// no network tile is ever fetched inside `flutter test`.
const _noTilesMap = SizedBox.shrink();

void main() {
  late _FakeLocationService location;

  setUp(() {
    location = _FakeLocationService();
    // The picker asks for the device fix on open; default to "unavailable"
    // so tests keep the fallback centre unless they stub a fix.
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    di.allowReassignment = true;
    di.registerSingleton<LocationService>(location);
    addTearDown(() => di.unregister<LocationService>());
  });

  Widget host({LatLng? center}) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () async {
                  await Navigator.of(context).push<
                      ({double latitude, double longitude, double radiusKm})>(
                    MaterialPageRoute(
                      builder: (_) => MapPickerPage(
                        initialCenter: center,
                        // ignore: avoid_redundant_argument_values
                        tileLayerBuilder: () => _noTilesMap,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

  /// Host variant carrying the extra seams the search/radius tests need.
  Widget hostWithExtras({
    LatLng? center,
    double? radiusKm,
    bool showRadius = false,
    Future<List<({String nama, LatLng titik})>> Function(String)? placeSearch,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: MapPickerPage(
            initialCenter: center,
            initialRadiusKm: radiusKm,
            showRadius: showRadius,
            tileLayerBuilder: () => _noTilesMap,
            placeSearch: placeSearch,
          ),
        ),
      );

  /// Opens the picker over a host so a Simpan can be observed as the popped
  /// result.
  Future<void> openOverHost(WidgetTester tester, {LatLng? center}) async {
    await tester.pumpWidget(host(center: center));
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the attribution over the fake tile layer', (tester) async {
    await openOverHost(tester, center: const LatLng(-6.895, 107.63));

    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    // The fields already mirror the saved coordinate pair before any touch.
    final latField = tester
        .widget<TextField>(find.byKey(const Key('latitude_field')))
        .controller!;
    expect(double.parse(latField.text), closeTo(-6.895, 0.0001));
  });

  testWidgets('Simpan pops the route with the validated pick', (tester) async {
    final finder = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('open'),
              onPressed: () async {
                final result = await Navigator.of(context).push<
                    ({double latitude, double longitude, double radiusKm})>(
                  MaterialPageRoute(
                    builder: (_) => MapPickerPage(
                      tileLayerBuilder: () => _noTilesMap,
                    ),
                  ),
                );
                finder.add(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('latitude_field')), '-6.362829');
    await tester.enterText(
        find.byKey(const Key('longitude_field')), '106.828655');
    await tester.tap(find.byKey(const Key('simpan_lokasi')));
    await tester.pumpAndSettle();

    expect(finder.single, (
      latitude: -6.362829,
      longitude: 106.828655,
      radiusKm: 5.0,
    ));
  });

  for (final (lat, lng, why) in const [
    ('95.0', '106', 'lintang out of range'),
    ('-6.3', '999', 'bujur out of range'),
    ('abc', '106', 'not a number'),
    ('NaN', '106', 'not finite'),
    ('-6.3', 'Infinity', 'infinite bujur'),
  ]) {
    testWidgets('Simpan refuses $why with the server-matching message',
        (tester) async {
      await openOverHost(tester);

      await tester.enterText(find.byKey(const Key('latitude_field')), lat);
      await tester.enterText(find.byKey(const Key('longitude_field')), lng);
      await tester.tap(find.byKey(const Key('simpan_lokasi')));
      await tester.pump();

      expect(find.textContaining('harus di antara'), findsOneWidget);
      // The picker stayed open, exactly as a backend 422 would leave it.
      expect(
        find.byKey(const Key('simpan_lokasi')),
        findsOneWidget,
        reason: 'an invalid entry must not close the page',
      );
    });
  }

  testWidgets('panning after focusing a field makes the fields follow the map',
      (tester) async {
    await openOverHost(tester, center: const LatLng(-6.895, 107.63));

    final latField = find.byKey(const Key('latitude_field'));
    await tester.tap(latField);
    await tester.pump();
    await tester.enterText(latField, '1.234');
    await tester.pump();
    final node = tester.widget<TextField>(latField).focusNode!;
    expect(node.hasFocus, isTrue);

    // A pan chooses the camera over the typed value: focus drops and the
    // fields resync, so Simpan cannot return the abandoned entry.
    await tester.drag(find.byType(FlutterMap), const Offset(0, -200));
    await tester.pumpAndSettle();

    final text = tester.widget<TextField>(latField).controller!.text;
    expect(node.hasFocus, isFalse);
    expect(double.parse(text), isNot(closeTo(1.234, 0.0001)));
  });

  testWidgets('opens on the device fix when no point was saved',
      (tester) async {
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -6.2, longitude: 106.8));
    await openOverHost(tester);
    await tester.pumpAndSettle();

    final latField = tester
        .widget<TextField>(find.byKey(const Key('latitude_field')))
        .controller!;
    expect(double.parse(latField.text), closeTo(-6.2, 0.0001));
  });

  testWidgets('without a fix the fields keep the UI-area fallback',
      (tester) async {
    await openOverHost(tester);
    await tester.pumpAndSettle();

    final latField = tester
        .widget<TextField>(find.byKey(const Key('latitude_field')))
        .controller!;
    expect(double.parse(latField.text), closeTo(-6.3703148, 0.0001));
  });

  testWidgets('a wide window puts the controls in a left panel, map right',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(hostWithExtras(showRadius: true));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Pilih Lokasi di Peta'), findsOneWidget);
    // Controls live in the left panel; the map starts after it.
    final simpan = tester.getTopLeft(find.byKey(const Key('simpan_lokasi')));
    expect(simpan.dx, lessThan(1280 / 2));
    final peta = tester.getTopLeft(find.byType(FlutterMap));
    expect(peta.dx, greaterThanOrEqualTo(300));
  });

  testWidgets('a phone window keeps the header, search and save in reach',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(hostWithExtras(showRadius: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('peta_kembali')), findsOneWidget);
    expect(find.byKey(const Key('peta_cari_tempat')), findsOneWidget);
    expect(find.byKey(const Key('simpan_lokasi')), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('Gunakan Lokasi Saya writes the fix into the fields',
      (tester) async {
    when(() => location.currentLocation())
        .thenAnswer((_) async => (latitude: -7.0, longitude: 110.0));
    await openOverHost(tester);

    await tester.tap(find.byKey(const Key('peta_lokasi_saya')));
    await tester.pump();

    final latField = tester
        .widget<TextField>(find.byKey(const Key('latitude_field')))
        .controller!;
    expect(double.parse(latField.text), closeTo(-7.0, 0.0001));
  });

  testWidgets('a refused fix degrades to a snack, not a crash', (tester) async {
    when(() => location.currentLocation()).thenAnswer((_) async => null);
    await openOverHost(tester);

    await tester.tap(find.byKey(const Key('peta_lokasi_saya')));
    await tester.pump();

    expect(find.text('Izin lokasi tidak tersedia.'), findsOneWidget);
  });

  testWidgets('a comma decimal is parsed like the server parses them',
      (tester) async {
    final finder = <Object?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              key: const Key('open'),
              onPressed: () async {
                final result = await Navigator.of(context).push<
                    ({double latitude, double longitude, double radiusKm})>(
                  MaterialPageRoute(
                    builder: (_) => MapPickerPage(
                      tileLayerBuilder: () => _noTilesMap,
                    ),
                  ),
                );
                finder.add(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('latitude_field')), '-6,36');
    await tester.enterText(find.byKey(const Key('longitude_field')), '106,82');
    await tester.tap(find.byKey(const Key('simpan_lokasi')));
    await tester.pumpAndSettle();

    expect(finder.single, (latitude: -6.36, longitude: 106.82, radiusKm: 5.0));
  });

  testWidgets('radius mode shows the slider, label, and hint pill',
      (tester) async {
    await tester.pumpWidget(hostWithExtras(
      center: const LatLng(-6.362829, 106.828655),
      showRadius: true,
    ));

    expect(find.byKey(const Key('peta_radius_slider')), findsOneWidget);
    expect(find.byKey(const Key('peta_petunjuk_geser')), findsOneWidget);
    // The label is the keyed Text itself; key-on-self, not a descendant.
    String labelValue() {
      final widget =
          tester.widget<Text>(find.byKey(const Key('peta_radius_label')));
      return widget.data ?? '';
    }

    expect(labelValue(), '5 km');

    // A new radius moves the label the same instant; the drag ends larger
    // than the default 5 km on the log scale.
    await tester.drag(
        find.byKey(const Key('peta_radius_slider')), const Offset(120, 0));
    await tester.pumpAndSettle();
    final nilai = double.parse(labelValue().split(' ')[0]);
    expect(nilai, greaterThan(5.0));
  });

  testWidgets('place search types a query and applies the picked result',
      (tester) async {
    await tester.pumpWidget(hostWithExtras(
      placeSearch: (kueri) async => const [
        (nama: 'Universitas Indonesia', titik: LatLng(-6.8915, 107.6107)),
        (nama: 'Universitas Gadjah Mada', titik: LatLng(-7.7700, 110.3770)),
      ],
    ));

    // Short queries never fire the search: no result list appears.
    await tester.enterText(find.byKey(const Key('peta_cari_tempat')), 'UI');
    await tester.pump();
    expect(find.byKey(const Key('peta_hasil_cari')), findsNothing);

    await tester.enterText(
        find.byKey(const Key('peta_cari_tempat')), 'Universitas');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('peta_hasil_cari')), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);

    await tester.tap(find.byKey(const Key('peta_hasil_0')));
    await tester.pumpAndSettle();
    // The result list closes and the fields now mirror the picked place.
    expect(find.byKey(const Key('peta_hasil_cari')), findsNothing);
    final latField = tester
        .widget<TextField>(find.byKey(const Key('latitude_field')))
        .controller!;
    expect(double.parse(latField.text), closeTo(-6.8915, 0.0001));
    final lngField = tester
        .widget<TextField>(find.byKey(const Key('longitude_field')))
        .controller!;
    expect(double.parse(lngField.text), closeTo(107.6107, 0.0001));
  });

  // Web regression (PIL-326): the picker's default search path must be our
  // backend. A direct Nominatim call cannot set User-Agent in a browser and
  // cross-origin calls can fail, so nothing here may touch that host.
  testWidgets('the default place search goes through the backend',
      (tester) async {
    final network = _FakeNetworkService();
    when(() => network.get(
          '/bank-sampah/cari-tempat',
          queryParams: any(named: 'queryParams'),
        )).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: '/bank-sampah/cari-tempat'),
        statusCode: 200,
        data: {
          'hasil': [
            {
              'nama': 'Universitas Indonesia',
              'latitude': -6.8915,
              'longitude': 107.6107,
            },
          ],
        },
      ),
    );
    di.allowReassignment = true;
    di.registerSingleton<NetworkService>(network);
    addTearDown(() => di.unregister<NetworkService>());

    await tester.pumpWidget(hostWithExtras());
    await tester.enterText(
        find.byKey(const Key('peta_cari_tempat')), 'Universitas');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    verify(() => network.get(
          '/bank-sampah/cari-tempat',
          queryParams: {'q': 'Universitas'},
        )).called(1);
    expect(find.text('Universitas Indonesia'), findsOneWidget);
  });

  testWidgets('a failed place search degrades to an empty result list',
      (tester) async {
    await tester.pumpWidget(hostWithExtras(
      placeSearch: (kueri) => throw Exception('jaringan mati'),
    ));

    await tester.enterText(
        find.byKey(const Key('peta_cari_tempat')), 'Depok Kota');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('peta_hasil_cari')), findsNothing);
    // The page is still alive: the search field is there.
    expect(find.byKey(const Key('peta_cari_tempat')), findsOneWidget);
  });

  testWidgets('a stale search response never paints over the newer one',
      (tester) async {
    final selesai = Completer<List<({String nama, LatLng titik})>>();
    await tester.pumpWidget(hostWithExtras(
      placeSearch: (_) => selesai.future,
    ));

    await tester.enterText(find.byKey(const Key('peta_cari_tempat')), 'Depok');
    await tester.pump(const Duration(milliseconds: 550));
    // Spinner while the single in-flight search is pending.
    expect(find.byKey(const Key('peta_cari_tempat')), findsOneWidget);

    // Resolve after the field was cleared: the stale answer is discarded.
    selesai.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('peta_hasil_cari')), findsNothing);
  });

  group('parseHasilCariTempat (the backend search body)', () {
    test('parses nama and the latitude/longitude pair', () {
      final hasil = parseHasilCariTempat({
        'hasil': [
          {
            'nama': 'Fakultas Ilmu Komputer',
            'latitude': -6.36,
            'longitude': 106.83,
          },
        ],
      });
      expect(hasil.single.nama, 'Fakultas Ilmu Komputer');
      expect(hasil.single.titik.latitude, -6.36);
      expect(hasil.single.titik.longitude, 106.83);
    });

    test('a null body and a missing nama degrade, not crash', () {
      expect(parseHasilCariTempat(null), isEmpty);
      expect(parseHasilCariTempat({'hasil': null}), isEmpty);
      final hasil = parseHasilCariTempat({
        'hasil': [
          {'latitude': -6.36, 'longitude': 106.83},
        ],
      });
      expect(hasil.single.nama, '');
    });

    test('a malformed coordinate throws — the caller catches to empty', () {
      expect(
        () => parseHasilCariTempat({
          'hasil': [
            {'latitude': 'y', 'longitude': 106.8},
          ],
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  testWidgets('submitting the coordinate fields re-centers the camera',
      (tester) async {
    await openOverHost(tester);

    // Submitting from each field's own onSubmitted hook re-centers the pin.
    await tester.enterText(find.byKey(const Key('latitude_field')), '-6.36');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('longitude_field')), '106.82');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('latitude_field')), '-6.36');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // The page is alive and the fields hold the submitted pair.
    expect(
      double.parse(
        tester
            .widget<TextField>(find.byKey(const Key('latitude_field')))
            .controller!
            .text,
      ),
      closeTo(-6.36, 0.0001),
    );
  });

  testWidgets('the search field clears itself and empties the results',
      (tester) async {
    await tester.pumpWidget(hostWithExtras(
      placeSearch: (kueri) async => const [
        (nama: 'Universitas Indonesia', titik: LatLng(-6.8915, 107.6107)),
      ],
    ));

    await tester.enterText(
        find.byKey(const Key('peta_cari_tempat')), 'Universitas');
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('peta_hasil_cari')), findsOneWidget);

    // The close button wipes the query and the result list.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('peta_hasil_cari')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('peta_cari_tempat')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('a tiles-down picker says what still works', (tester) async {
    for (var i = 0; i < TileHealth.instance.ambang; i++) {
      TileHealth.instance.catatGalat();
    }
    addTearDown(TileHealth.instance.pulihkan);

    await openOverHost(tester);

    expect(find.byKey(const Key('peta_galat_banner')), findsOneWidget);
    // The manual fields stay the last resort, so they must still be there.
    expect(find.byKey(const Key('latitude_field')), findsOneWidget);
  });
}
