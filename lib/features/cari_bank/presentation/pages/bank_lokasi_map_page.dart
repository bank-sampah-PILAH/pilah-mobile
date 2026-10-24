import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';

/// Full-screen OSM map centered on one bank's coordinates (PIL-308 detail),
/// with an "Buka di Maps" launcher to the user's own maps app (geo: URI).
///
/// Tests inject [tileLayerBuilder] like the map picker; the OSM layer must
/// never be fetched inside `flutter test`.
class BankLokasiMapPage extends StatelessWidget {
  const BankLokasiMapPage({
    super.key,
    required this.nama,
    required this.latitude,
    required this.longitude,
    this.tileLayerBuilder = osmTileLayer,
  });

  final String nama;
  final double latitude;
  final double longitude;

  /// Test seam, same contract as MapPickerPage.
  final Widget Function() tileLayerBuilder;

  @override
  Widget build(BuildContext context) {
    final titik = LatLng(latitude, longitude);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Lokasi Bank Sampah',
          style: AppTextStyle.appBar.copyWith(color: NasabahStyle.ink),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: titik,
              initialZoom: 16,
            ),
            children: [
              tileLayerBuilder(),
              osmAttribution(),
              MarkerLayer(
                markers: [
                  Marker(
                    point: titik,
                    width: 44,
                    height: 44,
                    child: const KeyedSubtree(
                      key: Key('detail_bank_marker'),
                      child: _PinBank(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x29000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    nama,
                    style: AppTextStyle.title1.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  key: const Key('detail_bank_buka_di_maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.near_me, size: 18),
                  label: Text(
                    'Buka di Maps',
                    style: AppTextStyle.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri(
                      scheme: 'geo',
                      host: '0,0',
                      queryParameters: {'q': '$latitude,$longitude($nama)'},
                    );
                    try {
                      await launchUrl(uri);
                    } catch (_) {
                      // No maps app on the platform — nothing to recover.
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pin hijau pola peta bank (lingkaran hijau + titik).
class _PinBank extends StatelessWidget {
  const _PinBank();

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.greenDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.store, size: 18, color: Colors.white),
      );
}
