import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/mini_lokasi_map.dart';

// Same seam contract as the picker: no tile is ever fetched inside a test.
const _noTilesMap = SizedBox.shrink();

void main() {
  Future<void> pump(WidgetTester tester, LatLng titik) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body:
              MiniLokasiMap(titik: titik, tileLayerBuilder: () => _noTilesMap),
        ),
      ),
    );
  }

  testWidgets('renders the pin over the fake tile layer', (tester) async {
    await pump(tester, const LatLng(-6.362829, 106.828655));

    expect(find.byKey(const Key('mini_map_pin')), findsOneWidget);
    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('a moved coordinate recreates the map, not just the pin',
      (tester) async {
    await pump(tester, const LatLng(-6.362829, 106.828655));
    const kunciAwal = ValueKey<String>('mini-map--6.362829-106.828655');
    expect(tester.widget(find.byKey(kunciAwal)), isA<SizedBox>());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniLokasiMap(
            titik: const LatLng(-6.4, 106.9),
            tileLayerBuilder: () => _noTilesMap,
          ),
        ),
      ),
    );

    // The ValueKey lives on the enclosing SizedBox keyed by the coordinate;
    // a moved pin must replace the FlutterMap element (initialCenter is
    // only read at creation), not reuse the same one.
    const kunciBaru = ValueKey<String>('mini-map--6.4-106.9');
    expect(tester.widget(find.byKey(kunciBaru)), isA<SizedBox>());
    expect(find.byKey(kunciAwal), findsNothing);
  });
}
