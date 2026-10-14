import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/services/di.dart';

class _FakeLocationService extends Mock implements LocationService {}

// The test seam the page was built for: a tile layer that draws nothing, so
// no network tile is ever fetched inside `flutter test`.
const _noTilesMap = SizedBox.shrink();

void main() {
  late _FakeLocationService location;

  setUp(() {
    location = _FakeLocationService();
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
}
