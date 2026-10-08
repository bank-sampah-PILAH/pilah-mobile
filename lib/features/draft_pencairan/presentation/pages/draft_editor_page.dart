import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/draft_editor_cubit.dart';
import '../blocs/draft_editor_state.dart';
import '../widgets/draft_format.dart';
import '../widgets/draft_status_badge.dart';
import '../widgets/editor_item_card.dart';
import '../widgets/pencairan_ui.dart';
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
            body: SafeArea(
              child: Column(
                children: [
                  PencairanHeader(
                    title: state.draftId == null
                        ? 'Pencairan Baru'
                        : 'Draft Pencairan',
                    actions: [_menu(state)],
                  ),
                  Expanded(
                    child: state.phase == EditorPhase.loading
                        ? const Center(child: CircularProgressIndicator())
                        : _Form(state: state, nama: _nama),
                  ),
                ],
              ),
            ),
            bottomNavigationBar:
                state.status.terkunci || state.phase == EditorPhase.loading
                    ? null
                    : _BottomBar(state: state, onSave: cubit.save),
          ),
        ),
      ),
    );
  }

  Widget _menu(DraftEditorState state) {
    if (state.draftId == null || state.status != DraftStatus.draft) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      key: const Key('menu-editor'),
      icon: Icon(Icons.more_vert, color: Colors.grey[800]),
      onSelected: (value) {
        if (value == 'batalkan') _cancelDraft();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'batalkan', child: Text('Batalkan draft')),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('NAMA PENCAIRAN')),
              if (state.draftId != null) DraftStatusBadge(status: state.status),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('nama-draft'),
            controller: nama,
            readOnly: locked,
            onChanged: cubit.setNama,
            style: pencairanInputStyle,
            decoration: pencairanInputDecoration(
              hintText: 'Kosongkan untuk nama otomatis',
            ),
          ),
          if (state.dibuatOlehNama.isNotEmpty) ...[
            const SizedBox(height: 8),
            PencairanMetaLine(
              label: 'Dibuat oleh',
              nama: state.dibuatOlehNama,
              waktu: waktu(state.createdAt),
            ),
            PencairanMetaLine(
              label: 'Diubah oleh',
              nama: state.diubahOlehNama,
              waktu: waktu(state.updatedAt),
            ),
          ],
          const SizedBox(height: 24),
          if (!locked) ...[
            _GeneralOptions(state: state),
            const SizedBox(height: 24),
          ],
          const SectionLabel('RINGKASAN'),
          const SizedBox(height: 8),
          PencairanSummaryCard(rows: [
            SummaryRow(
              label: 'Total pencairan',
              value: rupiah(state.totalNominal),
              valueKey: const Key('total-nominal'),
            ),
            SummaryRow(
              label: 'Total potongan',
              value: rupiah(state.totalPotongan),
              valueKey: const Key('total-potongan'),
            ),
            SummaryRow(
              label: 'Total dibayar',
              value: rupiah(state.totalDibayar),
              valueKey: const Key('total-dibayar'),
              emphasized: true,
            ),
          ]),
          const SizedBox(height: 24),
          SectionLabel('NASABAH (${state.items.length})'),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GeneralOptions extends StatelessWidget {
  final DraftEditorState state;

  const _GeneralOptions({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftEditorCubit>();
    return PencairanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('UNTUK SEMUA NASABAH'),
          const SizedBox(height: 16),
          const SectionLabel.field('METODE'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              PencairanChip(
                key: const Key('metode-semua-tunai'),
                label: 'Semua tunai',
                selected: state.items.isNotEmpty &&
                    state.items.every((i) => i.metode == MetodePencairan.tunai),
                onTap: () => cubit.setMetodeSemua(MetodePencairan.tunai),
              ),
              PencairanChip(
                key: const Key('metode-semua-transfer'),
                label: 'Semua transfer',
                selected: state.items.isNotEmpty &&
                    state.items
                        .every((i) => i.metode == MetodePencairan.transfer),
                onTap: () => cubit.setMetodeSemua(MetodePencairan.transfer),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel.field('POTONGAN UMUM'),
          const SizedBox(height: 8),
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

class _BottomBar extends StatelessWidget {
  final DraftEditorState state;
  final VoidCallback onSave;

  const _BottomBar({required this.state, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final canSave = state.canSave &&
        !state.isBusy &&
        (state.dirty || state.draftId == null);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomPrimaryButton(
          key: const Key('simpan'),
          title: state.phase == EditorPhase.saving
              ? 'Menyimpan...'
              : 'Simpan Draft',
          onPressed: canSave ? onSave : null,
        ),
      ),
    );
  }
}
