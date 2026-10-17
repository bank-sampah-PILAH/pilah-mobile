import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_form_fields.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/pencairan_validator.dart';
import '../blocs/edit_pencairan_cubit.dart';
import '../blocs/edit_pencairan_state.dart';

/// Pengurus correct a recorded pencairan (PIL-230). Pops `true` once saved so
/// the caller can reload; the backend recomputes saldo and later snapshots.
class EditPencairanPage extends StatelessWidget {
  static const route = '/edit-pencairan';

  final Pencairan pencairan;

  const EditPencairanPage({super.key, required this.pencairan});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<EditPencairanCubit>(),
      child: EditPencairanView(pencairan: pencairan),
    );
  }
}

class EditPencairanView extends StatefulWidget {
  final Pencairan pencairan;
  final DateTime Function() now;

  const EditPencairanView({
    super.key,
    required this.pencairan,
    this.now = DateTime.now,
  });

  @override
  State<EditPencairanView> createState() => _EditPencairanViewState();
}

class _EditPencairanViewState extends State<EditPencairanView> {
  late final _nominalController =
      TextEditingController(text: widget.pencairan.nominal.toString());
  late final _keteranganController =
      TextEditingController(text: widget.pencairan.keterangan);
  final _alasanController = TextEditingController();
  late MetodePencairan _metode = widget.pencairan.metode;
  late DateTime _tanggal = widget.pencairan.tanggal ?? widget.now();

  /// A pencairan confirmed with a potongan keeps its nominal and tanggal, so
  /// the potongan stays consistent with them; only the rest can be corrected.
  bool get _terkunci => widget.pencairan.potongan > 0;

  /// Falls back to the current tanggal when the backend did not send a limit.
  DateTime get _tanggalMinimum =>
      widget.pencairan.tanggalEditMinimum ?? _tanggal;

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  int? get _nominal => int.tryParse(_nominalController.text);

  Future<void> _pickTanggal() async {
    if (_terkunci) return;
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateUtils.dateOnly(_tanggalMinimum),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    // Keep the recorded time of day, clamped to the allowed range.
    var tanggal = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _tanggal.hour,
      _tanggal.minute,
    );
    if (tanggal.isBefore(_tanggalMinimum)) tanggal = _tanggalMinimum;
    if (tanggal.isAfter(now)) tanggal = now;
    setState(() => _tanggal = tanggal);
  }

  Future<void> _confirmAndSubmit(int nominal) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Simpan perubahan pencairan?',
      message: 'Saldo nasabah dan pencairan sesudahnya akan dihitung ulang. '
          'Versi lama tetap tersimpan di riwayat perubahan.',
      confirmLabel: 'Simpan',
    );
    if (!confirmed || !mounted) return;
    await context.read<EditPencairanCubit>().submit(
          EditPencairanRequest(
            id: widget.pencairan.id,
            nominal: nominal,
            metode: _metode,
            tanggal: _tanggal,
            keterangan: _keteranganController.text,
            alasan: _alasanController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditPencairanCubit, EditPencairanState>(
      listener: (context, state) {
        if (state.status == EditStatus.success) {
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          AppNotification.showError(
            context,
            title: 'Perubahan gagal disimpan',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        final nominal = _nominal;
        final nominalError = PencairanValidator.nominalEdit(nominal);
        final canSubmit = state.status != EditStatus.submitting &&
            nominalError == null &&
            _alasanController.text.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            // A desktop window keeps the form to a readable column.
            child: ContentBounds(
              maxWidth: LayoutBreakpoint.formMaxWidth,
              child: Column(
                children: [
                  const AppBackHeader(title: 'Edit Pencairan'),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.pencairan.nasabahNama,
                              style: AppTextStyle.title1),
                          const SizedBox(height: 16),
                          if (_terkunci) ...[
                            Text(
                              'Pencairan ini memakai potongan, jadi hanya metode '
                              'dan keterangan yang bisa diubah.',
                              style: AppTextStyle.small,
                            ),
                            const SizedBox(height: 16),
                          ],
                          const AppFieldLabel('NOMINAL'),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('nominal-field'),
                            controller: _nominalController,
                            enabled: !_terkunci,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: AppTextStyle.small
                                .copyWith(color: AppColors.black),
                            onChanged: (_) => setState(() {}),
                            decoration: appInputDecoration(
                              hintText: 'Contoh: 50000',
                              prefixText: 'Rp ',
                              errorText:
                                  nominalError ?? state.fieldErrors['nominal'],
                            ),
                          ),
                          const SizedBox(height: 16),
                          MetodePencairanSelector(
                            selected: _metode,
                            onChanged: (metode) =>
                                setState(() => _metode = metode),
                          ),
                          const SizedBox(height: 16),
                          TanggalPencairanField(
                            tanggal: _tanggal,
                            onTap: _pickTanggal,
                            errorText: state.fieldErrors['tanggal'],
                          ),
                          if (!_terkunci) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tanggal hanya bisa dimundurkan sampai '
                              '${formatTanggalId(_tanggalMinimum)}',
                              style: AppTextStyle.small,
                            ),
                          ],
                          const SizedBox(height: 16),
                          const AppFieldLabel('KETERANGAN (OPSIONAL)'),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('keterangan-field'),
                            controller: _keteranganController,
                            maxLength: 255,
                            maxLines: 2,
                            style: AppTextStyle.small
                                .copyWith(color: AppColors.black),
                            decoration: appInputDecoration(
                              hintText: 'Keterangan (opsional)',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const AppFieldLabel('ALASAN PERUBAHAN'),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('alasan-field'),
                            controller: _alasanController,
                            maxLength: 255,
                            maxLines: 2,
                            style: AppTextStyle.small
                                .copyWith(color: AppColors.black),
                            onChanged: (_) => setState(() {}),
                            decoration: appInputDecoration(
                              hintText: 'Mengapa pencairan ini diubah?',
                              errorText: state.fieldErrors['alasan'],
                            ).copyWith(
                              helperText:
                                  'Wajib diisi, tercatat di riwayat perubahan',
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppButton(
                key: const Key('submit-edit-pencairan'),
                label: state.status == EditStatus.submitting
                    ? 'Menyimpan...'
                    : 'Simpan Perubahan',
                onPressed: canSubmit ? () => _confirmAndSubmit(nominal!) : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
