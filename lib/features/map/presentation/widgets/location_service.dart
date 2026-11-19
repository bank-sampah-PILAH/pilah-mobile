import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

/// The device location as this app passes it around: a picked point, or
/// null when permission was refused or no fix exists.
typedef Lokasi = ({double latitude, double longitude});

/// Parses a serialized coordinate pair (the DRF `DecimalField` strings, e.g.
/// "106.828655" or "106.000000") into the [Lokasi] shape.
///
/// Returns null unless **both** boundaries arrived valid, so a partially
/// written pair degrades to "no location" instead of crashing coordinate
/// math downstream. Null is also what an unbackfilled bank sends.
Lokasi? parseLokasi(Object? latitude, Object? longitude) {
  final lat = double.tryParse(latitude?.toString() ?? '');
  final lng = double.tryParse(longitude?.toString() ?? '');
  if (lat == null || lng == null) return null;
  return (latitude: lat, longitude: lng);
}

/// Thin seam over geolocator so callers (map picker, dashboard prompt,
/// cari-bank start position) never touch the plugin directly and tests
/// inject a fake.
///
/// Null is the one "no location" outcome — permission prompts, denials,
/// service-offline and no-fix all degrade to it, so widget code stays a
/// nullable read instead of try/catch around the platform channel.
@lazySingleton
class LocationService {
  Future<Lokasi?> currentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          !await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      return (latitude: position.latitude, longitude: position.longitude);
    } on Exception {
      // Permission plumbing or the platform channel failing must never take
      // down the flow that merely wanted a starting point (web included).
      return null;
    }
  }
}
