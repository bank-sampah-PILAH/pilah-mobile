import 'dart:async';

import 'package:dio/dio.dart';
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
/// Marketplace-style radius: a circle around the center whose top handle is
/// dragged to resize. The popped record carries the radius beside the point.
///
/// Tests inject [tileLayerBuilder] to swap in a fake tile provider; the OSM
/// layer here must never be fetched inside `flutter test`.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({
    super.key,
    this.initialCenter,
    this.initialRadiusKm,
    this.tileLayerBuilder = osmTileLayer,
  });

  /// Where the pin starts. Defaults to somewhere over Indonesia when the
  /// caller has nothing saved; zoomed out enough to see, in enough to pick.
  final LatLng? initialCenter;

  /// Starting radius of the marketplace circle; defaults [radiusDefault].
  final double? initialRadiusKm;

  /// Test seam: builds the tile layer rendered under the pin. Loosely typed
  /// as any map child so a test can park a blank widget there instead of
  /// hand-rolling a TileProvider.
  final Widget Function() tileLayerBuilder;

  /// The default search radius when nothing was saved before.
  static const radiusDefault = 5.0;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final MapController _controller = MapController();
  final _cari = TextEditingController();
  final _cariFocus = FocusNode();
  List<({String nama, LatLng titik})> _hasilCari = [];
  bool _mencari = false;
  Timer? _jedaCari;
  int _percobaanCari = 0;

  /// Marketplace circle radius in km; handle drag updates it live.
  late double _radiusKm = widget.initialRadiusKm ?? MapPickerPage.radiusDefault;

  static const _defaultCenter = LatLng(-2.5, 118.0);

  /// Backend search cap (apps/bank_sampah/views.py JARAK_MAKSIMAL_KM).
  static const double _radiusMaksimalKm = 100;

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
    _cari.dispose();
    _cariFocus.dispose();
    _jedaCari?.cancel();
    super.dispose();
  }

  /// Nominatim place search (OpenStreetMap) — types "Universitas Indonesia",
  /// moves the camera to the best hit. Debounced per keystroke.
  Future<void> _cariTempat(String kata) async {
    _jedaCari?.cancel();
    final kueri = kata.trim();
    if (kueri.length < 3) {
      if (mounted) setState(() => _hasilCari = []);
      return;
    }
    _jedaCari = Timer(const Duration(milliseconds: 500), () {
      _panggilNominatim(kueri);
    });
  }

  Future<void> _panggilNominatim(String kueri) async {
    final percobaan = ++_percobaanCari;
    setState(() => _mencari = true);
    try {
      final response = await Dio().get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': kueri,
          'format': 'json',
          'limit': '5',
          'accept-language': 'id',
        },
        options: Options(
          headers: {'User-Agent': 'pilah-mobile/1.0 (pemilihan lokasi)'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (!mounted || percobaan != _percobaanCari) return;
      setState(() {
        _hasilCari = [
          for (final row in response.data ?? const [])
            (
              nama: (row as Map<String, dynamic>)['display_name'] as String? ??
                  '',
              titik: LatLng(
                double.parse(row['lat'] as String),
                double.parse(row['lon'] as String),
              ),
            ),
        ];
      });
    } on Exception {
      if (!mounted || percobaan != _percobaanCari) return;
      setState(() => _hasilCari = []);
    } finally {
      if (mounted) setState(() => _mencari = false);
    }
  }

  void _pilihHasil(({String nama, LatLng titik}) hasil) {
    _controller.move(hasil.titik, 17);
    _syncFieldsTo(hasil.titik);
    FocusScope.of(context).unfocus();
    setState(() => _hasilCari = []);
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
      Navigator.pop(
        context,
        (latitude: pair.$1, longitude: pair.$2, radiusKm: _radiusKm),
      );
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
                      onMapEvent: (event) {
                        _syncFieldsTo(event.camera.center);
                        // The circle is drawn anchored to the camera center;
                        // every pan/zoom repaints it around the new center.
                        if (mounted) setState(() {});
                      },
                    ),
                    children: [
                      widget.tileLayerBuilder(),
                      osmAttribution(),
                      _LingkaranRadius(
                        controller: _controller,
                        radiusKm: _radiusKm,
                      ),
                      // The fixed center dot: the map moves, the marker does
                      // not. Marketplace-style: a solid dot with a white ring.
                      const Center(
                        child: _TitikPusat(key: Key('peta_titik_pusat')),
                      ),
                    ],
                  ),
                  // The fixed center pin now lives inside the FlutterMap
                  // children so the radius circle tracks the same camera.
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
                  // Marketplace hint pill above the bottom panel.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Center(
                      child: Container(
                        key: const Key('peta_petunjuk_geser'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Geser peta untuk memilih lokasi',
                          style: NasabahStyle.text(
                            13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // GM-style place search over the map: type a place, tap a
                  // result, camera moves there.
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 12,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x29000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            key: const Key('peta_cari_tempat'),
                            controller: _cari,
                            focusNode: _cariFocus,
                            style: NasabahStyle.text(14),
                            onChanged: _cariTempat,
                            decoration: InputDecoration(
                              hintText:
                                  'Cari tempat (mis. Universitas Indonesia)',
                              hintStyle: NasabahStyle.text(13,
                                  color: NasabahStyle.muted),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.greenDark,
                              ),
                              suffixIcon: _mencari
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : (_cari.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _cari.clear();
                                            _cariTempat('');
                                          },
                                        )),
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        if (_hasilCari.isNotEmpty)
                          Container(
                            key: const Key('peta_hasil_cari'),
                            margin: const EdgeInsets.only(top: 4),
                            constraints: const BoxConstraints(maxHeight: 240),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x29000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _hasilCari.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) => ListTile(
                                key: Key('peta_hasil_$i'),
                                dense: true,
                                leading: const Icon(
                                  Icons.place_outlined,
                                  color: AppColors.greenDark,
                                  size: 20,
                                ),
                                title: Text(
                                  _hasilCari[i].nama,
                                  style: NasabahStyle.text(12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _pilihHasil(_hasilCari[i]),
                              ),
                            ),
                          ),
                      ],
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
                        Text(
                          'Radius:',
                          style:
                              NasabahStyle.text(14, color: NasabahStyle.muted),
                        ),
                        Expanded(
                          child: Slider(
                            key: const Key('peta_radius_slider'),
                            value: _radiusKm.clamp(0.5, _radiusMaksimalKm),
                            min: 0.5,
                            max: _radiusMaksimalKm,
                            activeColor: AppColors.greenDark,
                            onChanged: (km) => setState(() => _radiusKm = km),
                          ),
                        ),
                        Text(
                          '${_radiusKm.toStringAsFixed(_radiusKm == _radiusKm.roundToDouble() ? 0 : 1)} km',
                          key: const Key('peta_radius_label'),
                          style: NasabahStyle.text(
                            14,
                            weight: FontWeight.w600,
                            color: AppColors.greenDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

/// Titik pusat Marketplace-style: bulatan hijau pekat dengan cincin putih.
class _TitikPusat extends StatelessWidget {
  const _TitikPusat({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.greenDark,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
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

/// Lingkaran radius marketplace: hitungan kilometer di sekeliling titik
/// pusat, digambar ulang pada setiap gerak kamera supaya tetap melingkar
/// di permukaan peta.
class _LingkaranRadius extends StatelessWidget {
  final MapController controller;
  final double radiusKm;

  const _LingkaranRadius({required this.controller, required this.radiusKm});

  @override
  Widget build(BuildContext context) {
    final camera = controller.camera;
    return CircleLayer(
      circles: [
        CircleMarker(
          point: camera.center,
          // CircleLayer's meters mode is the honest ground-truth circle; the
          // pixel approximation below only positions the handle.
          useRadiusInMeter: true,
          radius: radiusKm * 1000,
          color: AppColors.greenDark.withValues(alpha: 0.12),
          borderStrokeWidth: 2,
          borderColor: AppColors.greenDark.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}
