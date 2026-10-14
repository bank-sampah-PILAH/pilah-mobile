import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';
import 'package:pilah_mobile/services/di.dart';

/// Full-screen OpenStreetMap picker (PIL-326).
///
/// The picked point is just the map's center: drag the map until the fixed
/// center pin sits on the spot — no draggable-marker internals, one source
/// of truth. The text fields mirror the camera while unfocused, and Simpan
/// reads the fields back (they either match the camera or hold a manual,
/// validated entry), so both input paths resolve through the same values.
///
/// Tests inject [tileLayerBuilder] to swap in a fake tile provider; the OSM
/// layer here must never be fetched inside `flutter test`.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    this.initialCenter,
    this.tileLayerBuilder = osmTileLayer,
  });

  /// Where the pin starts. Defaults to somewhere over Indonesia when the
  /// caller has nothing saved; zoomed out enough to see, in enough to pick.
  final LatLng? initialCenter;

  /// Test seam: builds the tile layer rendered under the pin. Loosely typed
  /// as any map child so a test can park a blank widget there instead of
  /// hand-rolling a TileProvider.
  final Widget Function() tileLayerBuilder;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final MapController _controller = MapController();

  static const _defaultCenter = LatLng(-2.5, 118.0);

  final _latitudeField = TextEditingController();
  final _longitudeField = TextEditingController();
  final _latitudeFocus = FocusNode();
  final _longitudeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncFieldsTo(widget.initialCenter ?? _defaultCenter);
  }

  @override
  void dispose() {
    _latitudeField.dispose();
    _longitudeField.dispose();
    _latitudeFocus.dispose();
    _longitudeFocus.dispose();
    super.dispose();
  }

  void _syncFieldsTo(LatLng point) {
    // A focused field is being typed into; never clobber it from the camera.
    if (_latitudeFocus.hasFocus || _longitudeFocus.hasFocus) return;
    _latitudeField.text = point.latitude.toStringAsFixed(6);
    _longitudeField.text = point.longitude.toStringAsFixed(6);
  }

  /// The fields parsed as a coordinate pair, or null with the offending
  /// message surfaced — the exact rule the server enforces (PIL-326).
  (double, double)? _validatedFields(BuildContext context) {
    final lat = double.tryParse(_latitudeField.text.replaceFirst(',', '.'));
    final lng = double.tryParse(_longitudeField.text.replaceFirst(',', '.'));
    String? message;
    if (lat == null || lat < -90 || lat > 90) {
      message = 'Lintang harus di antara -90 dan 90';
    } else if (lng == null || lng < -180 || lng > 180) {
      message = 'Bujur harus di antara -180 dan 180';
    }
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.black.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
    return (lat!, lng!);
  }

  /// Centers the camera on the (already validated) fields, so what Simpan
  /// will return is also what the pin is pointing at.
  void _moveCameraToFields() {
    final pair = _validatedFields(context);
    if (pair != null) _controller.move(LatLng(pair.$1, pair.$2), 17);
  }

  Future<void> _useMyLocation() async {
    final lokasi = await di<LocationService>().currentLocation();
    if (lokasi == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi tidak tersedia.')),
        );
      }
      return;
    }
    if (mounted) {
      _controller.move(LatLng(lokasi.latitude, lokasi.longitude), 17);
    }
  }

  // Simpan reads the fields — mirror of the camera or a manual entry that
  // just passed validation — so both input paths resolve the same way.
  void _simpan() {
    final pair = _validatedFields(context);
    if (pair == null) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, (latitude: pair.$1, longitude: pair.$2));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Pilih Lokasi di Peta',
            style: AppTextStyle.appBar.copyWith(color: NasabahStyle.ink),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCenter: widget.initialCenter ?? _defaultCenter,
                      initialZoom: 16,
                      onMapEvent: (event) => _syncFieldsTo(event.camera.center),
                    ),
                    children: [
                      widget.tileLayerBuilder(),
                      osmAttribution(),
                    ],
                  ),
                  // The fixed center pin: the map moves, the marker does not.
                  // Green drop-pin with a soft shadow halo (GM-style).
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 52,
                          color: AppColors.greenDark,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 46),
                      ],
                    ),
                  ),
                  // Floating locate-me button over the map (GM-chrome).
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _MapFab(
                      key: const Key('peta_lokasi_saya'),
                      icon: Icons.my_location,
                      onTap: _useMyLocation,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom coordinate panel — rounded white card over the map.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('latitude_field'),
                            controller: _latitudeField,
                            focusNode: _latitudeFocus,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            style: NasabahStyle.text(14),
                            decoration:
                                NasabahStyle.input(hint: 'Lintang').copyWith(
                              labelText: 'Lintang',
                              labelStyle: NasabahStyle.text(
                                13,
                                color: NasabahStyle.muted,
                              ),
                              floatingLabelStyle: NasabahStyle.text(
                                13,
                                color: AppColors.greenDark,
                              ),
                            ),
                            onSubmitted: (_) => _moveCameraToFields(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('longitude_field'),
                            controller: _longitudeField,
                            focusNode: _longitudeFocus,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            style: NasabahStyle.text(14),
                            decoration:
                                NasabahStyle.input(hint: 'Bujur').copyWith(
                              labelText: 'Bujur',
                              labelStyle: NasabahStyle.text(
                                13,
                                color: NasabahStyle.muted,
                              ),
                              floatingLabelStyle: NasabahStyle.text(
                                13,
                                color: AppColors.greenDark,
                              ),
                            ),
                            onSubmitted: (_) => _moveCameraToFields(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomPrimaryButton(
                      key: const Key('simpan_lokasi'),
                      title: 'Simpan Lokasi',
                      onPressed: _simpan,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

/// Lingkaran putih melayang di atas peta, ikon hijau — kontrol peta ala
/// Google Maps.
class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapFab({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: AppColors.greenDark),
        ),
      );
}
