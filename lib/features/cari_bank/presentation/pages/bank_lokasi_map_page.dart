import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';

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
      body: Column(
        children: [
          const AppBackHeader(
            title: 'Lokasi Bank Sampah',
            backKey: Key('lokasi_kembali'),
          ),
          Expanded(
            // PIL-326: the coordinate and the maps deep link are all a nasabah
            // needs; the tiles are a nicety, so an outage drops to a card.
            child: AnimatedBuilder(
              animation: TileHealth.instance,
              builder: (context, _) => TileHealth.instance.buruk
                  ? _petaTidakTersedia()
                  : Stack(
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
                          child: _kartuBawah(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Name card + maps launcher, shared by the live map and the outage card.
  Widget _kartuBawah() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              nama,
              style: AppTextStyle.title1.copyWith(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.lg,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tombolBukaMaps(),
        ],
      );

  /// Full-screen card shown while no tile source answers.
  Widget _petaTidakTersedia() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.map_outlined,
                  size: 44, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(
                'Peta sedang tidak tersedia',
                key: const Key('detail_bank_peta_galat'),
                textAlign: TextAlign.center,
                style: AppTextStyle.title1.copyWith(
                  fontWeight: AppFontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Koordinat bank: '
                '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                key: const Key('detail_bank_koordinat'),
                textAlign: TextAlign.center,
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
              const SizedBox(height: 20),
              _kartuBawah(),
            ],
          ),
        ),
      );

  Widget _tombolBukaMaps() => AppButton(
        key: const Key('detail_bank_buka_di_maps'),
        label: 'Buka di Maps',
        variant: AppButtonVariant.primary,
        trailingIcon: Icons.near_me,
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
      );
}

/// Pin hijau pola peta bank (lingkaran hijau + titik).
class _PinBank extends StatelessWidget {
  const _PinBank();

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.greenDark,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.place, color: Colors.white, size: 20),
      );
}
