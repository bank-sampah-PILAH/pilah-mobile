import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';

/// The map furniture both OSM screens share (PIL-326): exactly one place
/// carries the tile sources and attribution decided in PIL-326 — the tile
/// policy asks for a per-app user agent and a visible attribution line.
///
/// PIL-326 fallback: a second free host covers a single host going down.
/// Failures between free hosts are correlated (they block at similar request
/// rates), so treat this as time bought, not as an SLA — owning the tiles is
/// the only real fix.
///
/// Tiles are also cached on disk by flutter_map's default network provider on
/// native; on web the browser HTTP cache does the same job.
Widget osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      fallbackUrl:
          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      userAgentPackageName: 'id.pilah.app',
      // Fires only when every configured source failed, which is exactly the
      // "maps are down" signal the degraded screens read.
      errorTileCallback: (tile, error, stackTrace) =>
          TileHealth.instance.catatGalat(),
    );

RichAttributionWidget osmAttribution() => const RichAttributionWidget(
      attributions: [
        TextSourceAttribution('© OpenStreetMap contributors'),
        TextSourceAttribution('© CARTO'),
      ],
    );
