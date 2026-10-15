import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// The map furniture both OSM screens share (PIL-326): exactly one place
/// carries the tile source and attribution decided in PIL-326 — the tile
/// policy asks for a per-app user agent and a visible attribution line.
Widget osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'id.pilah.app',
    );

RichAttributionWidget osmAttribution() => const RichAttributionWidget(
      attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
    );
