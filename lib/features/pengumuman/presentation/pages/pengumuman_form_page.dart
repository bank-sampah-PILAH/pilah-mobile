import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
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

  PengumumanEntity _entity() {
    // Only a scheduled row keeps terbit_pada in a plain save: a draft's
    // schedule belongs to the Jadwalkan/Terbitkan actions, so "Simpan
    // Draft" never sends one the backend would label terjadwal without
    // ever publishing (review finding PIL-243).
    final keepsSchedule = _isTerjadwal;
    return PengumumanEntity(
      id: widget.existing?.id ?? '',
      bankSampahId: widget.existing?.bankSampahId ?? '',
      judul: _judul.text.trim(),
      isi: _isi.text.trim(),
      terbitPada: keepsSchedule ? _terbitPada : null,
      masaBerlakuHingga: _masaBerlakuHingga,
      status: widget.existing?.status ?? 'draft',
    );
  }

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

  /// Returns the row id a publish action targets, or null after showing why.
  Future<String?> _idUntukTerbit({required bool jadwalkan}) async {
    if (jadwalkan && _terbitPada == null) {
      setState(
          () => _validationError = 'Pilih waktu terbit untuk menjadwalkan.');
      return null;
    }
    if (!await _simpanPerubahan()) return null;

    final id = _savedId ?? widget.existing?.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return null;
      AppNotification.showError(context,
          title: 'Gagal', message: 'Pengumuman belum tersimpan.');
      return null;
    }
    return id;
  }

  Future<void> _terbitkan({required bool jadwalkan}) async {
    final id = await _idUntukTerbit(jadwalkan: jadwalkan);
    if (id == null || !mounted) return;

    // A scheduled row keeps its schedule from the PATCH above; everything
    // else publishes through the terbitkan action (null terbit_pada = now).
    NetworkException? failure;
    if (!_isTerjadwal) {
      failure = await _cubit.terbitkan(
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PengumumanCubit, PengumumanState>(
        builder: (context, state) {
          final busy = state is PengumumanLoaded &&
              (state.isSaving || state.isTransitioning);
          return SafeArea(
            child: Column(
              children: [
                AppBackHeader(
                    title: _isEditing ? 'Ubah Pengumuman' : 'Buat Pengumuman'),
                Expanded(child: _bagianForm()),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _tombolAksi(busy),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bagianForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.greenDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'Pengumuman akan dikirim ke semua nasabah bank sampah Anda.',
            style: AppTextStyle.small.copyWith(color: AppColors.greenDark),
          ),
        ),
        const SizedBox(height: 16),
        Text('Judul', style: AppTextStyle.regularSemiBold),
        const SizedBox(height: 8),
        TextFormField(
          controller: _judul,
          maxLength: 150,
          decoration:
              appInputDecoration(hintText: 'Contoh: Kerja bakti akhir bulan'),
        ),
        const SizedBox(height: 16),
        Text('Isi Pengumuman', style: AppTextStyle.regularSemiBold),
        const SizedBox(height: 8),
        TextFormField(
          controller: _isi,
          maxLines: 6,
          decoration: appInputDecoration(hintText: 'Tulis isi pengumuman'),
        ),
        const SizedBox(height: 16),
        _WaktuField(
          label: 'Waktu Terbit (untuk jadwal)',
          value: _terbitPada,
          onPick: () => _pilihWaktu(isMasaBerlaku: false),
          onClear: _terbitPada == null
              ? null
              : () => setState(() {
                    _terbitPada = null;
                    _validationError = null;
                  }),
        ),
        const SizedBox(height: 12),
        _WaktuField(
          label: 'Masa Berlaku Hingga (opsional)',
          value: _masaBerlakuHingga,
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
          Text(
            _validationError!,
            style: AppTextStyle.small.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _tombolAksi(bool busy) {
    return Column(
      children: [
        AppButton(
          label: _isTerjadwal ? 'Simpan Perubahan' : 'Simpan Draft',
          onPressed: busy ? null : _simpanDraft,
        ),
        if (!_isTerjadwal) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Jadwalkan',
                  variant: AppButtonVariant.outlined,
                  onPressed: busy ? null : () => _terbitkan(jadwalkan: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Terbitkan Sekarang',
                  onPressed: busy ? null : () => _terbitkan(jadwalkan: false),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WaktuField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _WaktuField({
    required this.label,
    required this.value,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyle.regularSemiBold),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: appInputDecoration(hintText: 'Pilih waktu'),
                  child: Text(
                    text,
                    style: AppTextStyle.regularSemiBold.copyWith(
                      color:
                          waktu == null ? AppColors.grey200 : AppColors.black,
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
        ),
      ],
    );
  }
}
