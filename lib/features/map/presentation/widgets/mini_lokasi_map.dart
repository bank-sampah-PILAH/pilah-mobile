import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';

/// Small non-interactive map preview with a pin (Marketplace-style "lokasi
/// bank" row): the pengaturan form shows this instead of raw coordinates,
/// and tapping it opens the full picker.
///
/// Tests inject [tileLayerBuilder] like the other map pages; the OSM layer
/// must never be fetched inside `flutter test`.
class MiniLokasiMap extends StatelessWidget {
  const MiniLokasiMap({
    super.key,
    required this.titik,
    this.height = 140,
    this.tileLayerBuilder = osmTileLayer,
  });

  final LatLng titik;
  final double height;

  /// Test seam, same contract as MapPickerPage.
  final Widget Function() tileLayerBuilder;

  @override
  Widget build(BuildContext context) => SizedBox(
        // Keyed on the coordinate: FlutterMap reads initialCenter only at
        // creation, so a parent rebuild with a moved pin must recreate it.
        key: ValueKey('mini-map-${titik.latitude}-${titik.longitude}'),
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: titik,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            tileLayerBuilder(),
            osmAttribution(),
            MarkerLayer(
              markers: [
                Marker(
                  point: titik,
                  width: 40,
                  height: 40,
                  child: const KeyedSubtree(
                    key: Key('mini_map_pin'),
                    child: Icon(
                      Icons.location_on,
                      size: 34,
                      color: AppColors.greenDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
