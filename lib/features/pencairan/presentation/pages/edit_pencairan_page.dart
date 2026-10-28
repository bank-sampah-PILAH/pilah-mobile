import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/widgets/app_date_picker.dart';
import 'package:flutter/services.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_panel_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_form_fields.dart';
import '../../domain/model/pencairan.dart';
import '../../domain/pencairan_validator.dart';
import '../states/edit_pencairan_state.dart';
import '../providers/edit_pencairan_provider.dart';

/// Pengurus correct a recorded pencairan (PIL-230). Pops `true` once saved so
/// the caller can reload; the backend recomputes saldo and later snapshots.
class EditPencairanPage extends StatelessWidget {
  static const route = '/edit-pencairan';

  final Pencairan pencairan;

  const EditPencairanPage({super.key, required this.pencairan});

  @override
  Widget build(BuildContext context) => EditPencairanView(pencairan: pencairan);
}

class EditPencairanView extends ConsumerStatefulWidget {
  final Pencairan pencairan;
  final DateTime Function() now;

  /// Inside a dialog on a wide window: no page scaffold, back header or
  /// bottom bar, so the nasabah list stays behind it.
  final bool embedded;

  /// With [embedded]: whether to draw its own title and close button. A
  /// side panel has one header for all its views and turns this off.
  final bool showHeader;

  /// Called instead of popping the route once the edit is saved.
  final VoidCallback? onSaved;

  const EditPencairanView({
    super.key,
    required this.pencairan,
    this.now = DateTime.now,
    this.embedded = false,
    this.showHeader = true,
    this.onSaved,
  });

  @override
  ConsumerState<EditPencairanView> createState() => _EditPencairanViewState();
}

class _EditPencairanViewState extends ConsumerState<EditPencairanView> {
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
    final picked = await showAppDatePicker(
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
    await ref.read(editPencairanProvider.notifier).submit(
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

  /// [inset] is the side room a wide window leaves around the form column, so
  /// the scroll view can span the body (scrollbar at the window edge).
  Widget _buildForm(
    EditPencairanState state,
    String? nominalError, {
    EdgeInsets inset = EdgeInsets.zero,
  }) {
    return SingleChildScrollView(
      padding: inset
          .add(const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.pencairan.nasabahNama, style: AppTextStyle.title1),
          const SizedBox(height: 16),
          if (_terkunci) ...[
            Text(
              'Pencairan ini memakai potongan, jadi nominal dan '
              'tanggalnya dikunci; hanya metode dan keterangan yang bisa '
              'diubah.',
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyle.small.copyWith(color: AppColors.black),
            onChanged: (_) => setState(() {}),
            decoration: appInputDecoration(
              hintText: 'Contoh: 50000',
              prefixText: 'Rp ',
              errorText: nominalError ?? state.fieldErrors['nominal'],
            ),
          ),
          const SizedBox(height: 16),
          MetodePencairanSelector(
            selected: _metode,
            onChanged: (metode) => setState(() => _metode = metode),
          ),
          const SizedBox(height: 16),
          TanggalPencairanField(
            tanggal: _tanggal,
            onTap: _pickTanggal,
            errorText: state.fieldErrors['tanggal'],
            enabled: !_terkunci,
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
            style: AppTextStyle.small.copyWith(color: AppColors.black),
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
            style: AppTextStyle.small.copyWith(color: AppColors.black),
            onChanged: (_) => setState(() {}),
            decoration: appInputDecoration(
              hintText: 'Mengapa pencairan ini diubah?',
              errorText: state.fieldErrors['alasan'],
            ).copyWith(
              helperText: 'Wajib diisi, tercatat di riwayat perubahan',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Sukses menutup form (memberi tahu pemanggil); gagal menampilkan pesannya.
  void _onState(BuildContext context, EditPencairanState state) {
    if (state.status == EditStatus.success) {
      final onSaved = widget.onSaved;
      onSaved != null ? onSaved() : Navigator.of(context).pop(true);
    } else if (state.errorMessage != null) {
      AppNotification.showError(
        context,
        title: 'Perubahan gagal disimpan',
        message: state.errorMessage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
        editPencairanProvider, (previous, state) => _onState(context, state));
    final state = ref.watch(editPencairanProvider);
    final nominal = _nominal;
    final nominalError = PencairanValidator.nominalEdit(nominal);
    final canSubmit = state.status != EditStatus.submitting &&
        nominalError == null &&
        _alasanController.text.trim().isNotEmpty;

    final form = _buildForm(state, nominalError);
    final submit = AppButton(
      key: const Key('submit-edit-pencairan'),
      label: state.status == EditStatus.submitting
          ? 'Menyimpan...'
          : 'Simpan Perubahan',
      onPressed: canSubmit ? () => _confirmAndSubmit(nominal!) : null,
    );
    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader)
            AppPanelHeader(
              title: 'Edit Pencairan',
              onClose: () => Navigator.of(context).maybePop(),
            ),
          Flexible(child: form),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: submit,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // A desktop window keeps the form to a readable column; the form
        // scrolls across the body so its scrollbar is at the window edge.
        child: ContentFrame(
          maxWidth: LayoutBreakpoint.formMaxWidth,
          child: Column(
            children: [
              const ContentInset(child: AppBackHeader(title: 'Edit Pencairan')),
              Expanded(
                child: Builder(
                  builder: (context) => _buildForm(
                    state,
                    nominalError,
                    inset: ContentFrame.insetOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // The save button keeps to the same column as the form, not the
      // whole width of the window.
      bottomNavigationBar: SafeArea(
        child: ContentBounds(
          maxWidth: LayoutBreakpoint.formMaxWidth,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: submit,
          ),
        ),
      ),
    );
  }
}
