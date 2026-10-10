import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/draft_editor_cubit.dart';
import '../blocs/draft_editor_state.dart';
import '../blocs/editor_item_view.dart';
import '../widgets/draft_file_actions.dart';
import '../widgets/draft_format.dart';
import '../widgets/draft_status_badge.dart';
import '../widgets/editor_item_card.dart';
import '../widgets/editor_item_controls.dart';
import '../widgets/editor_summary_panel.dart';
import '../widgets/export_menu_button.dart';
import '../widgets/jumlah_control.dart';
import '../widgets/pencairan_konfirmasi_sheet.dart';
import '../widgets/pencairan_ui.dart';
import '../widgets/potongan_control.dart';
import 'draft_editor_args.dart';
import 'draft_pdf_preview_page.dart';
import 'draft_list_page.dart';

/// Shapes a pencairan: name, general potongan and method, then each nasabah.
/// A saved draft can be resumed, paid (confirmed), cancelled or exported.
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

  Future<void> _confirmPayment() async {
    final cubit = context.read<DraftEditorCubit>();
    final state = cubit.state;
    final disimpanDulu = state.draftId == null || state.dirty;
    final ok = await showPencairanKonfirmasi(
      context,
      icon: Icons.payments_outlined,
      judul: 'Konfirmasi pembayaran',
      pesan: 'Lanjutkan hanya jika semua pembayaran sudah dilakukan.',
      isi: _RingkasanBayar(
        jumlah: state.items.length,
        total: state.totalDibayar,
        disimpanDulu: disimpanDulu,
      ),
      ya: 'Ya, sudah dibayar',
      tidak: 'Belum',
    );
    if (ok && mounted) await cubit.confirm();
  }

  Future<void> _export(ExportBerkas berkas) async {
    final cubit = context.read<DraftEditorCubit>();
    final file = await cubit.export(berkas);
    if (file == null || !mounted) return;

    if (berkas == ExportBerkas.pdf) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DraftPdfPreviewPage(file: file),
      ));
      return;
    }
    await simpanBerkasDraft(context, file);
  }

  /// A paid pencairan changes saldo and riwayat, so the screens that show
  /// them reload. Absent in a bare test tree, hence the guard.
  void _refreshRiwayat() {
    try {
      context.read<RiwayatAktivitasCubit>().load(silent: true);
      context.read<RecentActivityCubit>().load(silent: true);
    } on Object {
      // Not provided: nothing to refresh.
    }
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
              (a.phase == EditorPhase.confirming ||
                  a.phase == EditorPhase.cancelling),
          listener: (context, state) {
            final paid = state.status == DraftStatus.dikonfirmasi;
            if (paid) _refreshRiwayat();
            AppNotification.showSuccess(
              context,
              title: 'Berhasil',
              message: paid
                  ? 'Pembayaran dikonfirmasi. Saldo dan riwayat diperbarui.'
                  : 'Draft dibatalkan.',
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
            final buang = await showPencairanKonfirmasi(
              context,
              icon: Icons.warning_amber_rounded,
              judul: 'Buang perubahan?',
              pesan: 'Perubahan yang belum disimpan akan hilang.',
              ya: 'Buang',
              tidak: 'Tetap di sini',
              nada: KonfirmasiNada.peringatan,
            );
            if (buang && context.mounted) context.pop();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  PencairanHeader(
                    title:
                        state.draftId == null ? 'Pencairan Baru' : 'Pencairan',
                    actions: [
                      ExportMenuButton(
                        enabled: state.canExport,
                        busy: state.phase == EditorPhase.exporting,
                        onSelected: _export,
                      ),
                    ],
                  ),
                  Expanded(
                    child: state.phase == EditorPhase.loading
                        ? const Center(child: CircularProgressIndicator())
                        : _Form(state: state, nama: _nama),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: state.phase == EditorPhase.loading
                ? null
                : EditorSummaryPanel(
                    state: state,
                    aksi: state.status.terkunci
                        ? null
                        : _BottomBar(
                            state: state,
                            onSave: cubit.save,
                            onConfirm: _confirmPayment,
                          ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  final DraftEditorState state;
  final TextEditingController nama;

  const _Form({required this.state, required this.nama});

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  // What the list shows. The draft itself is untouched by any of it.
  final _cari = TextEditingController();
  ItemFilter _filter = ItemFilter.semua;
  ItemSort _urutan = const ItemSort.awal();

  // The order is frozen between sorts: sorting by dibayar while typing a nominal
  // would move the card away mid-keystroke. It is redone when the sort changes
  // or the set of nasabah does (added, removed, or a draft opened).
  Map<String, int>? _posisi;
  ItemSort? _posisiUrutan;
  Set<String>? _posisiId;

  Map<String, int> _urutanTetap(DraftEditorState state) {
    final ids = {for (final item in state.items) item.nasabahId};
    if (_posisi == null ||
        _posisiUrutan != _urutan ||
        !setEquals(_posisiId, ids)) {
      _posisi = EditorItemView.urutan(state, _urutan);
      _posisiUrutan = _urutan;
      _posisiId = ids;
    }
    return _posisi!;
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final nama = widget.nama;
    final cubit = context.read<DraftEditorCubit>();
    final locked = state.status.terkunci;
    final tampil = EditorItemView.tampilkan(
      state,
      query: _cari.text,
      filter: _filter,
      sort: _urutan,
      posisi: _urutanTetap(state),
    );
    // A lazy sliver list: a draft can hold hundreds of nasabah, and building a
    // card for each up front makes the screen slow to open and to scroll.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: SectionLabel('NAMA PENCAIRAN')),
                    if (state.draftId != null)
                      DraftStatusBadge(status: state.status),
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
                SectionLabel(
                  tampil.length == state.items.length
                      ? 'NASABAH (${state.items.length})'
                      : 'NASABAH (${tampil.length} dari ${state.items.length})',
                ),
                const SizedBox(height: 8),
                EditorItemControls(
                  state: state,
                  search: _cari,
                  filter: _filter,
                  sort: _urutan,
                  onSearch: (_) => setState(() {}),
                  onFilter: (f) => setState(() => _filter = f),
                  onSort: (field) =>
                      setState(() => _urutan = _urutan.pilih(field)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: tampil.isEmpty && state.items.isNotEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada nasabah yang cocok.',
                        style: AppTextStyle.small,
                      ),
                    ),
                  ),
                )
              : SliverList.separated(
                  itemCount: tampil.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = tampil[index];
                    return EditorItemCard(
                      key: ValueKey(item.nasabahId),
                      item: item,
                      state: state,
                      readOnly: locked,
                      onNominal: (nominal) =>
                          cubit.setItemNominal(item.nasabahId, nominal),
                      onMetode: (metode) =>
                          cubit.setItemMetode(item.nasabahId, metode),
                      onPotongan: (potongan) =>
                          cubit.setItemPotongan(item.nasabahId, potongan),
                      onRemove: () => cubit.removeItem(item.nasabahId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GeneralOptions extends StatefulWidget {
  final DraftEditorState state;

  const _GeneralOptions({required this.state});

  @override
  State<_GeneralOptions> createState() => _GeneralOptionsState();
}

/// Choices here wait for Terapkan, so one tap does not rewrite every card by
/// accident. Only what was touched is applied: changing the potongan leaves
/// amounts the pengurus set by hand alone.
class _GeneralOptionsState extends State<_GeneralOptions> {
  // What the pengurus has chosen here. Null means "as saved"; a choice equal to
  // the saved state is dropped again, so changing something back switches
  // Terapkan off.
  MetodePencairan? _metode;
  JumlahUmum? _jumlah;
  Potongan? _potongan;

  List<EditorItem> get _items => widget.state.items;

  /// "Semua tunai/transfer" as saved, or null when the cards differ.
  MetodePencairan? get _metodeTersimpan {
    if (_items.isEmpty) return null;
    final pertama = _items.first.metode;
    return _items.every((i) => i.metode == pertama) ? pertama : null;
  }

  /// The jumlah the cards agree on: the one kept with the draft while the cards
  /// still say so, else the whole saldo, or null when they were set by hand.
  JumlahUmum? get _jumlahTersimpan {
    if (_items.isEmpty) return null;
    bool cocok(JumlahUmum jumlah) =>
        _items.every((i) => i.nominal == jumlah.hitung(i.saldo));
    final terapan = widget.state.jumlahUmum;
    if (terapan != null && cocok(terapan)) return terapan;
    return cocok(JumlahUmum.penuh) ? JumlahUmum.penuh : null;
  }

  Potongan get _potonganTersimpan => widget.state.potonganDefault;

  bool get _metodeBerubah => _metode != null && _metode != _metodeTersimpan;
  bool get _jumlahBerubah => _jumlah != null && _jumlah != _jumlahTersimpan;
  bool get _potonganBerubah =>
      _potongan != null && _potongan != _potonganTersimpan;

  bool get _adaPerubahan =>
      _metodeBerubah || _jumlahBerubah || _potonganBerubah;

  bool get _siap => _adaPerubahan && (!_jumlahBerubah || _jumlah!.valid);

  void _terapkan() {
    final jumlah = _jumlahBerubah ? _jumlah : null;
    context.read<DraftEditorCubit>().terapkanUmum(
          metode: _metodeBerubah ? _metode : null,
          jumlah: jumlah,
          potongan: _potonganBerubah ? _potongan : null,
        );
    setState(() {
      _metode = null;
      _jumlah = null;
      _potongan = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metode = _metode ?? _metodeTersimpan;
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
                selected: metode == MetodePencairan.tunai,
                onTap: () => setState(() => _metode = MetodePencairan.tunai),
              ),
              PencairanChip(
                key: const Key('metode-semua-transfer'),
                label: 'Semua transfer',
                selected: metode == MetodePencairan.transfer,
                onTap: () => setState(() => _metode = MetodePencairan.transfer),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionLabel.field('JUMLAH PENCAIRAN'),
          const SizedBox(height: 8),
          JumlahControl(
            value: _jumlah ?? _jumlahTersimpan,
            onChanged: (jumlah) => setState(() => _jumlah = jumlah),
          ),
          const SizedBox(height: 16),
          const SectionLabel.field('POTONGAN UMUM'),
          const SizedBox(height: 8),
          PotonganControl(
            keyPrefix: 'potongan',
            value: _potongan ?? _potonganTersimpan,
            onChanged: (potongan) => setState(() => _potongan = potongan),
          ),
          const SizedBox(height: 16),
          if (_adaPerubahan) ...[
            Text(
              'Belum diterapkan',
              key: const Key('belum-diterapkan'),
              style: AppTextStyle.small.copyWith(
                color: AppColors.statOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Slimmer than the page's main buttons: this one sits inside a card.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('terapkan-umum'),
              onPressed: _siap ? _terapkan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Terapkan',
                style: AppTextStyle.title1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final DraftEditorState state;
  final VoidCallback onSave;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.state,
    required this.onSave,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canSave = state.canSave &&
        !state.isBusy &&
        (state.dirty || state.draftId == null);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: PencairanActionButton(
                key: const Key('simpan'),
                label: 'Simpan Draft',
                icon: Icons.save_outlined,
                isLoading: state.phase == EditorPhase.saving,
                onPressed: canSave ? onSave : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: PencairanActionButton(
                key: const Key('konfirmasi'),
                label: 'Konfirmasi Pembayaran',
                icon: Icons.check_circle_outline,
                filled: true,
                isLoading: state.phase == EditorPhase.confirming,
                onPressed: state.canConfirm ? onConfirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the payment sheet shows: who and how much is about to be paid, and the
/// warning that this cannot be undone.
class _RingkasanBayar extends StatelessWidget {
  final int jumlah;
  final int total;
  final bool disimpanDulu;

  const _RingkasanBayar({
    required this.jumlah,
    required this.total,
    required this.disimpanDulu,
  });

  @override
  Widget build(BuildContext context) {
    Widget baris(Key key, String label, Widget nilai) => Row(
          key: key,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label, style: AppTextStyle.small), nilai],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.greenLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              baris(
                const Key('konfirmasi-nasabah'),
                'Nasabah',
                Text('$jumlah',
                    style: AppTextStyle.small
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 10),
              baris(
                const Key('konfirmasi-total'),
                'Total dibayar',
                Text(
                  rupiah(total),
                  style: AppTextStyle.headline3.copyWith(
                    color: AppColors.greenDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('konfirmasi-peringatan'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statOrangeLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.statOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saldo nasabah akan dikurangi dan tercatat di riwayat. '
                  'Ini tidak bisa diulang.',
                  style: AppTextStyle.small,
                ),
              ),
            ],
          ),
        ),
        if (disimpanDulu) ...[
          const SizedBox(height: 12),
          Row(
            key: const Key('konfirmasi-simpan-dulu'),
            children: [
              Icon(Icons.save_outlined, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Draft akan disimpan terlebih dulu.',
                  style: AppTextStyle.small.copyWith(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
