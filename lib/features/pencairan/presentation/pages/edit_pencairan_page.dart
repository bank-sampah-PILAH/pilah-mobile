import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simpan perubahan pencairan?'),
        content: const Text(
          'Saldo nasabah dan pencairan sesudahnya akan dihitung ulang. '
          'Versi lama tetap tersimpan di riwayat perubahan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
          appBar: AppBar(title: const Text('Edit Pencairan')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.pencairan.nasabahNama,
                      style: AppTextStyle.title1),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('nominal-field'),
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nominal',
                      prefixText: 'Rp ',
                      border: const OutlineInputBorder(),
                      errorText: nominalError ?? state.fieldErrors['nominal'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Metode', style: AppTextStyle.small),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final metode in MetodePencairan.values)
                        ChoiceChip(
                          label: Text(metode.label),
                          selected: _metode == metode,
                          onSelected: (_) => setState(() => _metode = metode),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    key: const Key('tanggal-field'),
                    onTap: _pickTanggal,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_month),
                        errorText: state.fieldErrors['tanggal'],
                      ),
                      child: Text(formatTanggalId(_tanggal)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal hanya bisa dimundurkan sampai '
                    '${formatTanggalId(_tanggalMinimum)}',
                    style: AppTextStyle.small,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('keterangan-field'),
                    controller: _keteranganController,
                    maxLength: 255,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('alasan-field'),
                    controller: _alasanController,
                    maxLength: 255,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Alasan perubahan',
                      helperText: 'Wajib diisi, tercatat di riwayat perubahan',
                      border: const OutlineInputBorder(),
                      errorText: state.fieldErrors['alasan'],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomPrimaryButton(
                    key: const Key('submit-edit-pencairan'),
                    title: state.status == EditStatus.submitting
                        ? 'Menyimpan...'
                        : 'Simpan Perubahan',
                    onPressed:
                        canSubmit ? () => _confirmAndSubmit(nominal!) : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
