import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/draft_editor_cubit.dart';
import '../blocs/draft_editor_state.dart';
import '../widgets/draft_format.dart';
import '../widgets/draft_status_badge.dart';
import '../widgets/editor_item_card.dart';
import '../widgets/potongan_control.dart';
import 'draft_editor_args.dart';
import 'draft_list_page.dart';

/// Shapes a pencairan: name, general potongan and method, then each nasabah.
/// A saved draft can be resumed or cancelled.
class DraftEditorPage extends StatelessWidget {
  static const route = DraftListPage.routeEditor;

  final DraftEditorArgs args;

  const DraftEditorPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = di<DraftEditorCubit>();
        final id = args.draftId;
        if (id != null) {
          cubit.load(id);
        } else {
          cubit.startNew(args.kandidat);
        }
        return cubit;
      },
      child: const DraftEditorView(),
    );
  }
}

class DraftEditorView extends StatefulWidget {
  const DraftEditorView({super.key});

  @override
  State<DraftEditorView> createState() => _DraftEditorViewState();
}

class _DraftEditorViewState extends State<DraftEditorView> {
  late final TextEditingController _nama;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(
        text: context.read<DraftEditorCubit>().state.nama);
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String yes,
    String no = 'Batal',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(no),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _cancelDraft() async {
    final cubit = context.read<DraftEditorCubit>();
    final ok = await _confirmDialog(
      title: 'Batalkan draft?',
      message: 'Draft ini tidak akan dibayarkan. Saldo nasabah tidak berubah.',
      yes: 'Ya, batalkan',
      no: 'Kembali',
    );
    if (ok && mounted) await cubit.cancel();
  }

  void _onState(BuildContext context, DraftEditorState state) {
    if (_nama.text != state.nama) _nama.text = state.nama;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftEditorCubit>();
    return MultiBlocListener(
      listeners: [
        BlocListener<DraftEditorCubit, DraftEditorState>(listener: _onState),
        BlocListener<DraftEditorCubit, DraftEditorState>(
          listenWhen: (a, b) =>
              b.errorMessage != null && a.errorMessage != b.errorMessage,
          listener: (context, state) => AppNotification.showError(
            context,
            title: 'Gagal',
            message: state.errorMessage!,
          ),
        ),
        BlocListener<DraftEditorCubit, DraftEditorState>(
          // Only a payment or cancellation made here: merely opening a draft that
          // is already paid or cancelled changes the status too, silently.
          listenWhen: (a, b) =>
              a.status != b.status &&
              b.status.terkunci &&
              a.phase == EditorPhase.cancelling,
          listener: (context, state) {
            AppNotification.showSuccess(
              context,
              title: 'Berhasil',
              message: 'Draft dibatalkan.',
            );
          },
        ),
        BlocListener<DraftEditorCubit, DraftEditorState>(
          listenWhen: (a, b) =>
              a.phase == EditorPhase.saving &&
              b.phase == EditorPhase.idle &&
              !b.dirty &&
              b.errorMessage == null &&
              b.itemErrors.isEmpty &&
              a.status == b.status,
          listener: (context, state) => AppNotification.showSuccess(
            context,
            title: 'Berhasil',
            message: 'Draft disimpan.',
          ),
        ),
      ],
      child: BlocBuilder<DraftEditorCubit, DraftEditorState>(
        builder: (context, state) => PopScope(
          canPop: !state.dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final buang = await _confirmDialog(
              title: 'Buang perubahan?',
              message: 'Perubahan yang belum disimpan akan hilang.',
              yes: 'Buang',
              no: 'Tetap di sini',
            );
            if (buang && context.mounted) context.pop();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _appBar(state),
            body: state.phase == EditorPhase.loading
                ? const Center(child: CircularProgressIndicator())
                : _Form(state: state, nama: _nama),
            bottomNavigationBar:
                state.status.terkunci || state.phase == EditorPhase.loading
                    ? null
                    : _BottomBar(
                        state: state,
                        onSave: cubit.save,
                      ),
          ),
        ),
      ),
    );
  }

  AppBar _appBar(DraftEditorState state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.black),
      title: Text(
        state.draftId == null ? 'Pencairan Baru' : 'Draft Pencairan',
        style: AppTextStyle.appBar,
      ),
      actions: [
        if (state.draftId != null && state.status == DraftStatus.draft)
          PopupMenuButton<String>(
            key: const Key('menu-editor'),
            onSelected: (value) {
              switch (value) {
                case 'batalkan':
                  _cancelDraft();
              }
            },
            itemBuilder: (_) => [
              if (state.status == DraftStatus.draft)
                const PopupMenuItem(
                  value: 'batalkan',
                  child: Text('Batalkan draft'),
                ),
            ],
          ),
      ],
    );
  }
}

class _Form extends StatelessWidget {
  final DraftEditorState state;
  final TextEditingController nama;

  const _Form({required this.state, required this.nama});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftEditorCubit>();
    final locked = state.status.terkunci;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('nama-draft'),
                controller: nama,
                readOnly: locked,
                onChanged: cubit.setNama,
                decoration: InputDecoration(
                  labelText: 'Nama pencairan',
                  hintText: 'Kosongkan untuk nama otomatis',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (state.draftId != null) ...[
              const SizedBox(width: 8),
              DraftStatusBadge(status: state.status),
            ],
          ],
        ),
        if (state.dibuatOlehNama.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Dibuat oleh ${state.dibuatOlehNama} · ${waktu(state.createdAt)}',
            style: AppTextStyle.extraSmall,
          ),
          Text(
            'Diubah oleh ${state.diubahOlehNama} · ${waktu(state.updatedAt)}',
            style: AppTextStyle.extraSmall,
          ),
        ],
        const SizedBox(height: 16),
        if (!locked) _GeneralOptions(state: state),
        _Totals(state: state),
        const SizedBox(height: 16),
        Text('NASABAH (${state.items.length})',
            style: AppTextStyle.extraSmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            )),
        const SizedBox(height: 8),
        for (final item in state.items) ...[
          EditorItemCard(
            item: item,
            state: state,
            readOnly: locked,
            onNominal: (nominal) =>
                cubit.setItemNominal(item.nasabahId, nominal),
            onMetode: (metode) => cubit.setItemMetode(item.nasabahId, metode),
            onPotongan: (potongan) =>
                cubit.setItemPotongan(item.nasabahId, potongan),
            onReset: () => cubit.resetItem(item.nasabahId),
            onRemove: () => cubit.removeItem(item.nasabahId),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GeneralOptions extends StatelessWidget {
  final DraftEditorState state;

  const _GeneralOptions({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftEditorCubit>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Untuk semua nasabah', style: AppTextStyle.headline3),
          const SizedBox(height: 8),
          Text('Metode pembayaran', style: AppTextStyle.small),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                key: const Key('metode-semua-tunai'),
                label: const Text('Semua tunai'),
                onPressed: () => cubit.setMetodeSemua(MetodePencairan.tunai),
              ),
              ActionChip(
                key: const Key('metode-semua-transfer'),
                label: const Text('Semua transfer'),
                onPressed: () => cubit.setMetodeSemua(MetodePencairan.transfer),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Potongan umum', style: AppTextStyle.small),
          PotonganControl(
            keyPrefix: 'potongan',
            value: state.potonganDefault,
            onChanged: cubit.setPotonganDefault,
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final DraftEditorState state;

  const _Totals({required this.state});

  @override
  Widget build(BuildContext context) {
    Widget row(Key key, String label, int value, {bool bold = false}) => Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyle.small)),
            Text(
              rupiah(value),
              key: key,
              style: AppTextStyle.small.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          row(const Key('total-nominal'), 'Total pencairan',
              state.totalNominal),
          row(const Key('total-potongan'), 'Total potongan',
              state.totalPotongan),
          const Divider(),
          row(const Key('total-dibayar'), 'Total dibayar', state.totalDibayar,
              bold: true),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final DraftEditorState state;
  final VoidCallback onSave;

  const _BottomBar({
    required this.state,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final canSave = state.canSave &&
        !state.isBusy &&
        (state.dirty || state.draftId == null);
    ButtonStyle style(Color color, {bool outlined = false}) =>
        ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.white : color,
          foregroundColor: outlined ? color : Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: outlined ? BorderSide(color: color) : BorderSide.none,
          ),
          elevation: 0,
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('simpan'),
                onPressed: canSave ? onSave : null,
                style: style(AppColors.greenDark),
                child: state.phase == EditorPhase.saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Simpan Draft'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
