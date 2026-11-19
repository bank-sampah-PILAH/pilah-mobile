import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/features/map/data/datasources/koordinat_remote_data_source.dart';
import 'package:pilah_mobile/features/map/domain/entities/hasil_koordinat.dart';
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/mini_lokasi_map.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/osm_tiles.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/tile_health.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/onboarding_layout.dart';
import 'package:pilah_mobile/services/di.dart';

/// Optional bank coordinate section (PIL-326).
///
/// Four doors, cheapest first: the device fix, the address already typed in
/// the form above, a pasted Google Maps link, and the map picker. Only the
/// last one needs tiles, so a tile outage still lets a bank be placed.
///
/// It owns the whole interaction — asking, resolving, confirming, clearing —
/// and reports one value to the form. The enclosing screen keeps no coordinate
/// state, so "source without point" cannot be built.
class TitikLokasiField extends StatefulWidget {
  const TitikLokasiField({
    super.key,
    required this.alamat,
    required this.onChanged,
    this.initial,
    this.tileLayerBuilder,
  });

  /// Reads the address field of the enclosing form: door 2 must not ask the
  /// pengurus to type the same address twice.
  final String Function() alamat;

  /// Reports the chosen point, or null when it was cleared.
  final ValueChanged<TitikLokasiBank?> onChanged;

  final TitikLokasiBank? initial;

  /// Test seam threaded to the map picker; null = the real OSM layer.
  final Widget Function()? tileLayerBuilder;

  @override
  State<TitikLokasiField> createState() => _TitikLokasiFieldState();
}

class _TitikLokasiFieldState extends State<TitikLokasiField> {
  late TitikLokasiBank? _titik = widget.initial;

  /// One of the fallback lookups is in flight.
  bool _mencari = false;

  /// Input of the "paste a Google Maps link" dialog, owned here so closing the
  /// dialog never leaves a disposed controller behind.
  final _tautanController = TextEditingController();

  @override
  void dispose() {
    _tautanController.dispose();
    super.dispose();
  }

  void _terapkan(TitikLokasiBank? titik) {
    setState(() => _titik = titik);
    widget.onChanged(titik);
  }

  void _gagal(String pesan) => AppNotification.showError(
        context,
        title: 'Gagal',
        message: pesan,
      );

  /// Opens the map picker and keeps the result until the form is submitted.
  Future<void> _pilihDiPeta() async {
    final picked = await Navigator.of(context, rootNavigator: true)
        .push<({double latitude, double longitude, double radiusKm})>(
      MaterialPageRoute(
        builder: (_) => widget.tileLayerBuilder == null
            ? const MapPickerPage()
            : MapPickerPage(tileLayerBuilder: widget.tileLayerBuilder!),
      ),
    );
    if (picked == null || !mounted) return;
    // The picker returns the cari-bank trio; registration stores the pair.
    _terapkan(
      TitikLokasiBank(
        latitude: picked.latitude,
        longitude: picked.longitude,
        sumber: 'manual',
      ),
    );
  }

  /// Door 1: the phone's own fix. No tiles, no network beyond GPS.
  Future<void> _pakaiLokasiSaya() async {
    setState(() => _mencari = true);
    try {
      final lokasi = await di<LocationService>().currentLocation();
      if (!mounted) return;
      if (lokasi == null) {
        _gagal(
          'Lokasi perangkat tidak tersedia. Izinkan akses lokasi atau isi '
          'koordinat manual.',
        );
        return;
      }
      _terapkan(
        TitikLokasiBank(
          latitude: lokasi.latitude,
          longitude: lokasi.longitude,
          sumber: 'gps',
        ),
      );
    } catch (_) {
      if (mounted) _gagal('Lokasi perangkat tidak dapat dibaca. Coba lagi.');
    } finally {
      if (mounted) setState(() => _mencari = false);
    }
  }

  /// Door 2: look the typed address up on the server.
  Future<void> _dariAlamat() async {
    final alamat = widget.alamat().trim();
    if (alamat.isEmpty) {
      _gagal('Isi alamat bank sampah dulu, lalu ambil titiknya.');
      return;
    }
    await _resolusi(
      () => di<KoordinatRemoteDataSource>().dariAlamat(alamat: alamat),
    );
  }

  /// Door 3: paste an exact Google Maps link. Short links are expanded on the
  /// server — a browser cannot follow their redirects.
  Future<void> _dariTautan() async {
    final controller = _tautanController..clear();
    final tautan = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Tempel tautan Google Maps',
        content: TextField(
          key: const Key('tautan_maps_field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: appInputDecoration(
            hintText: 'https://maps.app.goo.gl/...',
          ),
        ),
        confirmLabel: 'Ambil koordinat',
        onConfirm: () => Navigator.pop(dialogContext, controller.text),
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
    if (tautan == null || tautan.trim().isEmpty) return;
    await _resolusi(
      () => di<KoordinatRemoteDataSource>().dariTautan(tautan),
    );
  }

  Future<void> _resolusi(Future<HasilKoordinat> Function() kerja) async {
    setState(() => _mencari = true);
    try {
      final hasil = await kerja();
      if (!mounted) return;
      _terapkan(
        TitikLokasiBank(
          latitude: hasil.latitude,
          longitude: hasil.longitude,
          sumber: hasil.sumber,
          alamat: hasil.alamatHasil,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _gagal(
        e is Exception
            ? NetworkException.handleException(e).displayMessage
            : 'Koordinat tidak dapat diambil. Coba lagi atau isi manual.',
      );
    } finally {
      if (mounted) setState(() => _mencari = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titik = _titik;
    return OnboardingFormField(
      label: 'TITIK LOKASI (OPSIONAL)',
      description: 'Tandai titik bank sampah agar dapat ditemukan pencari. '
          'Lewati bila tidak tersedia.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titik != null) ...[
            // Confirmation: the mini map while tiles answer, the matched
            // address text when they do not.
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: MiniLokasiMap(
                titik: LatLng(titik.latitude, titik.longitude),
                tileLayerBuilder: widget.tileLayerBuilder ?? osmTileLayer,
              ),
            ),
            if (titik.alamat != null) ...[
              const SizedBox(height: 6),
              Text(
                titik.alamat!,
                key: const Key('lokasi_alamat_hasil'),
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            ],
            const SizedBox(height: 8),
          ],
          _barisTerpilih(titik),
          // PIL-326 doors that still work while the tiles are down.
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                key: const Key('lokasi_pakai_gps'),
                label: 'Lokasi saya',
                icon: Icons.my_location,
                size: AppButtonSize.compact,
                variant: AppButtonVariant.outlined,
                expand: false,
                isLoading: _mencari,
                onPressed: _pakaiLokasiSaya,
              ),
              AppButton(
                key: const Key('lokasi_dari_alamat'),
                label: 'Dari alamat',
                icon: Icons.search,
                size: AppButtonSize.compact,
                variant: AppButtonVariant.outlined,
                expand: false,
                onPressed: _mencari ? null : _dariAlamat,
              ),
              AppButton(
                key: const Key('lokasi_dari_tautan'),
                label: 'Tempel tautan',
                icon: Icons.link,
                size: AppButtonSize.compact,
                variant: AppButtonVariant.outlined,
                expand: false,
                onPressed: _mencari ? null : _dariTautan,
              ),
            ],
          ),
          // PIL-326: say why the map door above is not the answer right now.
          if (TileHealth.instance.buruk) ...[
            const SizedBox(height: 8),
            Text(
              'Peta sedang tidak tersedia. Tiga tombol di atas tetap '
              'menyimpan titik bank.',
              key: const Key('lokasi_peta_galat'),
              style: AppTextStyle.small.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  /// The coordinate row: opens the picker, and clears the point when set.
  Widget _barisTerpilih(TitikLokasiBank? titik) => InkWell(
        onTap: _pilihDiPeta,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: titik != null ? AppColors.greenDark : AppColors.grey200,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titik != null
                      ? '${titik.latitude.toStringAsFixed(6)}, '
                          '${titik.longitude.toStringAsFixed(6)}'
                      : 'Pilih di peta',
                  style: TextStyle(
                    color: titik != null ? AppColors.black : AppColors.grey200,
                  ),
                ),
              ),
              if (titik != null)
                AppTapTarget(
                  label: 'Hapus titik',
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: () => _terapkan(null),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.grey200,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      );
}
