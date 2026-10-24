import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

/// One grid cluster: the banks it groups and their centroid, which is where
/// the cluster marker is drawn.
typedef BankKelompok = ({
  LatLng center,
  List<BankSampahDirectoryEntity> banks,
});

/// Groups geolocated banks into grid clusters for the PIL-330 map.
///
/// The cell edge shrinks with zoom (2/2^zoom degrees), so at any open zoom-
/// level the on-screen groupings stay roughly constant. Pure: no camera, no
/// state — the map view only feeds it the banks and the camera zoom. Banks
/// without coordinates are ignored (they are list-only per the issue).
List<BankKelompok> kelompokkanBank(
  List<BankSampahDirectoryEntity> banks,
  double zoom,
) {
  final cell = 2.0 / pow(2.0, zoom);
  final buckets = <String, List<BankSampahDirectoryEntity>>{};
  for (final bank in banks) {
    final lokasi = bank.lokasi;
    if (lokasi == null) continue;
    final key =
        '${(lokasi.latitude / cell).floor()}:${(lokasi.longitude / cell).floor()}';
    buckets.putIfAbsent(key, () => []).add(bank);
  }
  return [
    for (final members in buckets.values)
      (
        center: LatLng(
          members.map((b) => b.lokasi!.latitude).reduce((a, b) => a + b) /
              members.length,
          members.map((b) => b.lokasi!.longitude).reduce((a, b) => a + b) /
              members.length,
        ),
        banks: members,
      ),
  ];
}
