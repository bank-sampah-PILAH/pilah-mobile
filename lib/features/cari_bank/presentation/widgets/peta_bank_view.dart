import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/pages/bank_sampah_detail_page.dart';
import 'package:pilah_mobile/features/cari_bank/presentation/widgets/bank_marker_cluster.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/services/di.dart';

/// The rich side of the PIL-330 list/map toggle: the current search results
/// as clustered OSM markers that fit the results, with an optional jump to
/// the user location.
///
/// Tests inject [tileLayerBuilder] the same way the map picker does; the OSM
/// layer here must never be fetched inside `flutter test`.
class PetaBankView extends StatefulWidget {
  const PetaBankView({super.key, required this.banks, this.tileLayerBuilder});

  final List<BankSampahDirectoryEntity> banks;

  /// Test seam; defaults to the shared OSM layer (kept nullable so the page
  /// can pass `null` through without every caller importing the tile widget).
  final Widget Function()? tileLayerBuilder;

  @override
  State<PetaBankView> createState() => _PetaBankViewState();
}

class _PetaBankViewState extends State<PetaBankView> {
  late final MapController _controller = MapController();

  static const double _zoomAwal = 5;
  static const double _zoomUser = 15;

  /// Camera zoom the clusters were built for; the map view only ever reacts
  /// through this — nothing re-clusters silently behind a still frame.
  late double _zoom = _zoomAwal;

  /// Set once the map's camera exists; fitting before that is a no-op.
  bool _ready = false;

  void _syncZoom() {
    if (!mounted) return;
    final zoom = _controller.camera.zoom;
    if (zoom != _zoom) setState(() => _zoom = zoom);
  }

  List<LatLng> get _points => [
        for (final bank in widget.banks)
          if (bank.lokasi != null)
            LatLng(bank.lokasi!.latitude, bank.lokasi!.longitude),
      ];

  /// Refits the camera to the search results — a new query/filter is a new
  /// extent. Keys on list identity, not length: a reload may return the same
  /// count of banks.
  void _fitToResults() {
    if (_ready && _points.isNotEmpty) {
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: _points,
          padding: const EdgeInsets.all(48),
          // A single bank has no area: without a ceiling the fitted zoom is
          // infinite and the camera ctor asserts it away.
          maxZoom: 17,
        ),
      );
      _syncZoom();
    }
  }

  @override
  void initState() {
    super.initState();
    _lokasiPengguna();
  }

  /// Centers on the user when permission allows; a denial is not an error —
  /// the map just starts on the results fit (LocationService's contract).
  Future<void> _lokasiPengguna() async {
    final lokasi = await di<LocationService>().currentLocation();
    if (lokasi == null || !mounted) return;
    _controller.move(
      LatLng(lokasi.latitude, lokasi.longitude),
      _zoomUser,
    );
  }

  @override
  void didUpdateWidget(covariant PetaBankView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.banks, widget.banks)) _fitToResults();
  }

  void _tapKelompok(BankKelompok kelompok) {
    if (kelompok.banks.length > 1) {
      // Zooming one step in splits the cell; move also fires onMapEvent.
      _controller.move(kelompok.center, _zoom + 1);
      return;
    }
    _bukaRingkasan(kelompok.banks.single);
  }

  void _bukaRingkasan(BankSampahDirectoryEntity bank) {
    final lokasi = bank.lokasi!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bank.nama,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bank.kota} · ${bank.alamat}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${lokasi.latitude.toStringAsFixed(6)}, '
                '${lokasi.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('cari_bank_lihat_detail'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.push(BankSampahDetailPage.route, extra: bank.id);
                },
                icon: const Icon(Icons.description_outlined),
                label: const Text('Lihat Detail'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kelompok = kelompokkanBank(widget.banks, _zoom);
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCameraFit: _points.isEmpty
            ? null
            : CameraFit.coordinates(
                coordinates: _points,
                padding: const EdgeInsets.all(48),
                maxZoom: 17,
              ),
        onMapEvent: (_) => _syncZoom(),
        onMapReady: () {
          _ready = true;
          _syncZoom();
        },
      ),
      children: [
        (widget.tileLayerBuilder ?? osmTileLayer)(),
        osmAttribution(),
        MarkerLayer(
          markers: [
            for (final k in kelompok)
              Marker(
                point: k.center,
                width: 40,
                height: 40,
                child: GestureDetector(
                  key: k.banks.length > 1
                      ? const Key('cari_bank_cluster')
                      : Key('cari_bank_marker_${k.banks.first.id}'),
                  onTap: () => _tapKelompok(k),
                  child: k.banks.length > 1
                      ? _BadgeKelompok(count: k.banks.length)
                      : const _MarkerBank(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MarkerBank extends StatelessWidget {
  const _MarkerBank();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.store,
        size: 32,
        color: Colors.indigo,
        shadows: [Shadow(color: Colors.white, blurRadius: 4)],
      );
}

class _BadgeKelompok extends StatelessWidget {
  const _BadgeKelompok({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.indigo,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
