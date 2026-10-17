import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';

/// Arguments for the authoring form: a null pengumuman creates a new draft,
/// a non-null one edits that draft or scheduled announcement.
class PengumumanFormArgs {
  final PengumumanEntity? pengumuman;

  const PengumumanFormArgs({this.pengumuman});
}

/// Authoring screen for pengurus announcements (PIL-243). The audience is
/// fixed — every nasabah of the pengurus's own bank sampah — so there is no
/// target selector. Simpan Draft keeps a draft; Terbitkan publishes now or
/// schedules a future publish time.
class PengumumanFormPage extends StatelessWidget {
  const PengumumanFormPage({super.key, this.args});

  static const route = '/pengumuman/kelola/ubah';

  final PengumumanFormArgs? args;

  @override
  Widget build(BuildContext context) {
    final existing = args?.pengumuman;
    return BlocListener<PengumumanCubit, PengumumanState>(
      listener: (context, state) {
        if (state is PengumumanError) {
          AppNotification.showError(context,
              title: 'Gagal', message: state.message);
        }
      },
      child: _PengumumanFormBody(existing: existing),
    );
  }
}

class _PengumumanFormBody extends StatefulWidget {
  const _PengumumanFormBody({this.existing});

  final PengumumanEntity? existing;

  @override
  State<_PengumumanFormBody> createState() => _PengumumanFormBodyState();
}

class _PengumumanFormBodyState extends State<_PengumumanFormBody> {
  late final TextEditingController _judul;
  late final TextEditingController _isi;
  DateTime? _terbitPada;
  DateTime? _masaBerlakuHingga;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _judul = TextEditingController(text: existing?.judul ?? '');
    _isi = TextEditingController(text: existing?.isi ?? '');
    _terbitPada = existing?.terbitPada;
    _masaBerlakuHingga = existing?.masaBerlakuHingga;
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;
  bool get _isTerjadwal => widget.existing?.isTerjadwal ?? false;

  Future<void> _pilihWaktu({required bool isMasaBerlaku}) async {
    final current = isMasaBerlaku ? _masaBerlakuHingga : _terbitPada;
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? firstDate.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _validationError = null;
      if (isMasaBerlaku) {
        _masaBerlakuHingga =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
      } else {
        _terbitPada =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    });
  }

  String? _validate() {
    if (_judul.text.trim().isEmpty) return 'Judul wajib diisi.';
    if (_isi.text.trim().isEmpty) return 'Isi pengumuman wajib diisi.';
    final now = DateTime.now();
    if (_terbitPada != null && _terbitPada!.isBefore(now)) {
      return 'Waktu terbit harus di masa datang.';
    }
    if (_masaBerlakuHingga != null) {
      final terkait = _terbitPada ?? now;
      if (!_masaBerlakuHingga!.isAfter(terkait)) {
        return 'Masa berlaku harus setelah waktu terbit.';
      }
    }
    return null;
  }

  PengumumanEntity _entity() => PengumumanEntity(
        id: widget.existing?.id ?? '',
        bankSampahId: widget.existing?.bankSampahId ?? '',
        judul: _judul.text.trim(),
        isi: _isi.text.trim(),
        terbitPada: _terbitPada,
        masaBerlakuHingga: _masaBerlakuHingga,
        status: widget.existing?.status ?? 'draft',
      );

  String? _savedId;

  PengumumanCubit get _cubit => context.read<PengumumanCubit>();

  Future<bool> _simpanPerubahan() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return false;
    }
    final cubit = _cubit;
    final result = await cubit.savePengumuman(_entity());
    if (!mounted) return false;
    String? failureMessage;
    result.fold(
      (failure) => failureMessage = failure.displayMessage,
      (saved) => _savedId = saved.id,
    );
    if (failureMessage != null) {
      AppNotification.showError(context,
          title: 'Gagal', message: failureMessage!);
      return false;
    }
    return true;
  }

  Future<void> _simpanDraft() async {
    if (!await _simpanPerubahan()) return;
    if (!mounted) return;
    // Pop first: the toast belongs to the screen we return to, and popping
    // under an open toast trips the navigator in tests and in production.
    final editing = _isEditing;
    Navigator.of(context).pop(true);
    AppNotification.afterNavigation(
        (toastContext) => AppNotification.showSuccess(
              toastContext,
              title: 'Tersimpan',
              message: editing
                  ? 'Pengumuman diperbarui.'
                  : 'Pengumuman disimpan sebagai draft.',
            ));
  }

  Future<void> _terbitkan({required bool jadwalkan}) async {
    if (jadwalkan && _terbitPada == null) {
      setState(
          () => _validationError = 'Pilih waktu terbit untuk menjadwalkan.');
      return;
    }
    if (!await _simpanPerubahan()) return;

    final id = _savedId ?? widget.existing?.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      AppNotification.showError(context,
          title: 'Gagal', message: 'Pengumuman belum tersimpan.');
      return;
    }
    // A scheduled row keeps its schedule from the PATCH above; everything
    // else publishes through the terbitkan action (null terbit_pada = now).
    NetworkException? failure;
    if (!_isTerjadwal) {
      final cubit = _cubit;
      failure = await cubit.terbitkan(
        id,
        terbitPada: jadwalkan ? _terbitPada : null,
        masaBerlakuHingga: _masaBerlakuHingga,
      );
    }
    if (!mounted) return;
    if (failure != null) {
      AppNotification.showError(
        context,
        title: 'Gagal',
        message: failure.displayMessage,
      );
      return;
    }
    final scheduled = jadwalkan;
    Navigator.of(context).pop(true);
    AppNotification.afterNavigation(
        (toastContext) => AppNotification.showSuccess(
              toastContext,
              title: scheduled ? 'Terjadwal' : 'Terbit',
              message: scheduled
                  ? 'Pengumuman dijadwalkan terbit.'
                  : 'Pengumuman diterbitkan.',
            ));
  }

  @override
  Widget build(BuildContext context) {
    // Page shape copied from Transaksi Baru: grey-tile back button + headline
    // in a padded header row (no AppBar), sections announced by small
    // uppercase grey captions, and helper text under the section label.
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PengumumanCubit, PengumumanState>(
        builder: (context, state) {
          final isSaving = state is PengumumanLoaded && state.isSaving;
          final isTransitioning =
              state is PengumumanLoaded && state.isTransitioning;
          final busy = isSaving || isTransitioning;
          return AbsorbPointer(
            absorbing: busy,
            child: SafeArea(
              child: ContentBounds(
                child: Column(
                  children: [
                    // Header — same back-tile + title row as Transaksi Baru.
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.arrow_back,
                                  color: Colors.grey[800], size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _isEditing
                                  ? 'Ubah Pengumuman'
                                  : 'Buat Pengumuman',
                              style: AppTextStyle.appBar.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        children: [
                          // Section 1: ISI PENGUMUMAN
                          Text(
                            'PENGUMUMAN',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.greenDark.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.campaign_outlined,
                                    color: AppColors.greenDark, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pengumuman akan dikirim ke semua nasabah bank sampah Anda.',
                                    style: AppTextStyle.small
                                        .copyWith(color: AppColors.greenDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Judul', style: AppTextStyle.regularSemiBold),
                          const SizedBox(height: 4),
                          Text(
                            'Maksimal 150 karakter. Contoh: Kerja bakti akhir bulan.',
                            style: AppTextStyle.small
                                .copyWith(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _judul,
                            maxLength: 150,
                            decoration: appInputDecoration(
                                hintText: 'Tulis judul pengumuman'),
                          ),
                          const SizedBox(height: 16),
                          Text('Isi Pengumuman',
                              style: AppTextStyle.regularSemiBold),
                          const SizedBox(height: 4),
                          Text(
                            'Beritahu yang akan dilakukan, tanggalnya, dan siapa yang harus datang.',
                            style: AppTextStyle.small
                                .copyWith(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _isi,
                            maxLines: 6,
                            decoration: appInputDecoration(
                                hintText: 'Tulis isi pengumuman'),
                          ),
                          const SizedBox(height: 24),

                          // Section 2: JADWAL (opsional)
                          Text(
                            'JADWAL (OPSIONAL)',
                            style: AppTextStyle.extraSmall.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Waktu Terbit',
                              style: AppTextStyle.regularSemiBold),
                          const SizedBox(height: 4),
                          Text(
                            'Kosongkan untuk menyimpan sebagai draft. Isi lalu tekan "Jadwalkan" untuk terbit otomatis nanti.',
                            style: AppTextStyle.small
                                .copyWith(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          _WaktuField(
                            value: _terbitPada,
                            hint: 'Pilih waktu terbit',
                            onPick: () => _pilihWaktu(isMasaBerlaku: false),
                            onClear: _terbitPada == null
                                ? null
                                : () => setState(() {
                                      _terbitPada = null;
                                      _validationError = null;
                                    }),
                          ),
                          const SizedBox(height: 16),
                          Text('Masa Berlaku Hingga',
                              style: AppTextStyle.regularSemiBold),
                          const SizedBox(height: 4),
                          Text(
                            'Setelah lewat waktu ini pengumuman berhenti tampil untuk nasabah.',
                            style: AppTextStyle.small
                                .copyWith(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          _WaktuField(
                            value: _masaBerlakuHingga,
                            hint: 'Pilih masa berlaku',
                            onPick: () => _pilihWaktu(isMasaBerlaku: true),
                            onClear: _masaBerlakuHingga == null
                                ? null
                                : () => setState(() {
                                      _masaBerlakuHingga = null;
                                      _validationError = null;
                                    }),
                          ),
                          if (_validationError != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                _validationError!,
                                style: AppTextStyle.small
                                    .copyWith(color: Colors.red),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CustomPrimaryButton(
                            title: _isTerjadwal
                                ? 'Simpan Perubahan'
                                : 'Simpan Draft',
                            onPressed: busy ? null : _simpanDraft,
                          ),
                          if (!_isTerjadwal) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => _terbitkan(jadwalkan: true),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Jadwalkan',
                                      style: AppTextStyle.title1.copyWith(
                                        color: AppColors.greenDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomPrimaryButton(
                                    title: 'Terbitkan Sekarang',
                                    onPressed: busy
                                        ? null
                                        : () => _terbitkan(jadwalkan: false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaktuField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _WaktuField({
    required this.value,
    required this.hint,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final waktu = value;
    final text = waktu == null
        ? 'Belum dipilih'
        : '${waktu.day}/${waktu.month}/${waktu.year} '
            '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: appInputDecoration(hintText: hint),
              child: Text(
                text,
                style: AppTextStyle.regularSemiBold.copyWith(
                  color: waktu == null ? AppColors.grey200 : Colors.black,
                ),
              ),
            ),
          ),
        ),
        if (onClear != null)
          IconButton(
            tooltip: 'Hapus waktu',
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 20),
          ),
      ],
    );
  }
}
