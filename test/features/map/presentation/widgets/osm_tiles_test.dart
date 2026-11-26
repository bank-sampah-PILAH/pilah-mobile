import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';

/// Only its identity matters here; the layer hands it straight back.
class _FakeTile extends Mock implements TileImage {}

void main() {
  final tile = _FakeTile();

  tearDown(TileHealth.instance.pulihkan);

  test('carries a second free host for when the first one fails', () {
    final layer = osmTileLayer() as TileLayer;

    expect(layer.urlTemplate, contains('tile.openstreetmap.org'));
    expect(layer.fallbackUrl, contains('basemaps.cartocdn.com'));
  });

  test('a tile that failed on every source degrades the shared health signal',
      () {
    final layer = osmTileLayer() as TileLayer;

    for (var i = 0; i < TileHealth.instance.ambang; i++) {
      layer.errorTileCallback!(tile, Exception('tile down'), null);
    }

    expect(TileHealth.instance.buruk, isTrue);
  });

  test('attribution credits both hosts that may have drawn the map', () {
    final attribution = osmAttribution();

    final sources = attribution.attributions
        .whereType<TextSourceAttribution>()
        .map((source) => source.text);

    expect(sources, contains('© OpenStreetMap contributors'));
    expect(sources, contains('© CARTO'));
  });
}
