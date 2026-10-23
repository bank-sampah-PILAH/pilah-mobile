import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/repository/draft_pencairan_repository.dart';
import '../providers/draft_editor_provider.dart';
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
    return ProviderScope(
      overrides: [
        draftEditorProvider.overrideWith(
          () => DraftEditorNotifier(di<DraftPencairanRepository>()),
        ),
      ],
      child: _DraftEditorInitializer(args: args),
    );
  }
}

class _DraftEditorInitializer extends ConsumerStatefulWidget {
  const _DraftEditorInitializer({required this.args});

  final DraftEditorArgs args;

  @override
  ConsumerState<_DraftEditorInitializer> createState() =>
      _DraftEditorInitializerState();
}

class _DraftEditorInitializerState
    extends ConsumerState<_DraftEditorInitializer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(draftEditorProvider.notifier);
      final id = widget.args.draftId;
      if (id != null) {
        notifier.load(id);
      } else {
        notifier.startNew(widget.args.kandidat);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const DraftEditorView();
}

class DraftEditorView extends ConsumerStatefulWidget {
  const DraftEditorView({super.key});

  @override
  ConsumerState<DraftEditorView> createState() => _DraftEditorViewState();
}

class _DraftEditorViewState extends ConsumerState<DraftEditorView> {
  late final TextEditingController _nama;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: ref.read(draftEditorProvider).nama);
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final notifier = ref.read(draftEditorProvider.notifier);
    final state = ref.read(draftEditorProvider);
    final ok = await showPencairanKonfirmasi(
      context,
      icon: Icons.payments_outlined,
      judul: 'Konfirmasi pembayaran',
      pesan: 'Lanjutkan hanya jika semua pembayaran sudah dilakukan.',
      isi: _RingkasanBayar(
        jumlah: state.items.length,
        total: state.totalDibayar,
      ),
      jawaban: const KonfirmasiJawaban('Ya, sudah dibayar', 'Belum'),
    );
    if (ok && mounted) await notifier.confirm();
  }

  Future<void> _export(ExportBerkas berkas) async {
    final notifier = ref.read(draftEditorProvider.notifier);
    final file = await notifier.export(berkas);
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
    final providers = ProviderScope.containerOf(context, listen: false);
    if (providers.exists(riwayatAktivitasProvider)) {
      providers.read(riwayatAktivitasProvider.notifier).load(silent: true);
    }
    if (providers.exists(recentActivityProvider)) {
      providers.read(recentActivityProvider.notifier).load(silent: true);
    }
  }

  void _onState(BuildContext context, DraftEditorState state) {
    if (_nama.text != state.nama) _nama.text = state.nama;
  }

  // A new error to show.
  static bool _newError(DraftEditorState a, DraftEditorState b) =>
      b.errorMessage != null && a.errorMessage != b.errorMessage;

  // Only a payment or cancellation made here: merely opening a draft that is
  // already paid or cancelled changes the status too, silently.
  static bool _finishedHere(DraftEditorState a, DraftEditorState b) =>
      a.status != b.status &&
      b.status.terkunci &&
      (a.phase == EditorPhase.confirming || a.phase == EditorPhase.cancelling);

  void _onFinished(BuildContext context, DraftEditorState state) {
    final paid = state.status == DraftStatus.dikonfirmasi;
    if (paid) _refreshRiwayat();
    AppNotification.showSuccess(
      context,
      title: 'Berhasil',
      message: paid
          ? 'Pembayaran dikonfirmasi. Saldo dan riwayat diperbarui.'
          : 'Draft dibatalkan.',
      actionLabel: paid ? 'Lihat riwayat' : null,
      onAction: paid
          ? () => context.go('${AppLocations.history}?filter=pencairan')
          : null,
    );
  }

  static bool _savedCleanly(DraftEditorState a, DraftEditorState b) =>
      a.phase == EditorPhase.saving &&
      b.phase == EditorPhase.idle &&
      !b.dirty &&
      b.errorMessage == null &&
      b.itemErrors.isEmpty &&
      a.status == b.status;

  static void _toast(BuildContext context, String title, String message) =>
      AppNotification.showSuccess(context, title: title, message: message);

  Future<void> _onPopBlocked(BuildContext context, bool didPop) async {
    if (didPop) return;
    final buang = await showPencairanKonfirmasi(
      context,
      icon: Icons.warning_amber_rounded,
      judul: 'Buang perubahan?',
      pesan: 'Perubahan yang belum disimpan akan hilang.',
      jawaban: const KonfirmasiJawaban('Buang', 'Tetap di sini'),
      nada: KonfirmasiNada.peringatan,
    );
    if (buang && context.mounted) context.pop();
  }

  // One key for both layouts: the form moves between two trees when the
  // window crosses the desktop breakpoint, and its search, filter and sort
  // must move with it instead of resetting.
  final _formKey = GlobalKey();

  Widget _form(DraftEditorState state, {double leftInset = 0}) =>
      _Form(key: _formKey, state: state, nama: _nama, leftInset: leftInset);

  Widget _scaffold(BuildContext context, DraftEditorState state) {
    final notifier = ref.read(draftEditorProvider.notifier);
    final loading = state.phase == EditorPhase.loading;
    final header = AppBackHeader(
      backKey: const Key('kembali'),
      title: state.draftId == null ? 'Pencairan Baru' : 'Pencairan',
      actions: [
        ExportMenuButton(
          enabled: state.canExport,
          busy: state.phase == EditorPhase.exporting,
          onSelected: _export,
        ),
      ],
    );
    // On a desktop window the totals and the buttons that act on them sit in
    // a panel beside the nasabah list, not in a bar across the whole width.
    if (context.layoutBreakpoint == LayoutBreakpoint.expanded) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          // Both panes scroll out to the window edges, so their scrollbars sit
          // there; the frame's inset keeps the content to a readable column.
          child: ContentFrame(
            child: Column(
              children: [
                ContentInset(child: header),
                Expanded(
                  child: Builder(builder: (context) {
                    final inset = ContentFrame.insetOf(context);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: loading
                              ? const Center(child: CircularProgressIndicator())
                              : _form(state, leftInset: inset.left),
                        ),
                        SizedBox(
                          width: LayoutBreakpoint.sidePanelWidth + inset.right,
                          child: SingleChildScrollView(
                            key: const Key('draft-editor-panel'),
                            padding: EdgeInsets.fromLTRB(
                                16, 16, 16 + inset.right, 16),
                            child: EditorSummaryPanel(
                              state: state,
                              samping: true,
                              aksi: loading || state.status.terkunci
                                  ? null
                                  : _BottomBar(
                                      state: state,
                                      onSave: notifier.save,
                                      onConfirm: _confirmPayment,
                                      tumpuk: true,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            header,
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _form(state),
            ),
          ],
        ),
      ),
      bottomNavigationBar: loading
          ? null
          : EditorSummaryPanel(
              state: state,
              aksi: state.status.terkunci
                  ? null
                  : _BottomBar(
                      state: state,
                      onSave: notifier.save,
                      onConfirm: _confirmPayment,
                    ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(draftEditorProvider, (previous, state) {
      if (previous == null) return;
      _onState(context, state);
      if (_newError(previous, state)) {
        AppNotification.showError(
          context,
          title: 'Gagal',
          message: state.errorMessage!,
        );
      }
      if (_finishedHere(previous, state)) _onFinished(context, state);
      if (_savedCleanly(previous, state)) {
        _toast(context, 'Berhasil', 'Draft disimpan.');
      }
    });
    final state = ref.watch(draftEditorProvider);
    return PopScope(
      // A draft that was never saved is all unsaved work, edited or not.
      canPop: state.draftId != null && !state.dirty,
      onPopInvokedWithResult: (didPop, _) => _onPopBlocked(context, didPop),
      child: _scaffold(context, state),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  final DraftEditorState state;
  final TextEditingController nama;

  /// Room a wide window leaves left of the content column; the form grows into
  /// it so the scroll view starts at the window edge.
  final double leftInset;

  const _Form({
    super.key,
    required this.state,
    required this.nama,
    this.leftInset = 0,
  });

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
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
    final notifier = ref.read(draftEditorProvider.notifier);
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
          padding: EdgeInsets.fromLTRB(16 + widget.leftInset, 8, 16, 0),
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
                  onChanged: notifier.setNama,
                  style: appInputStyle,
                  decoration: appInputDecoration(
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
          padding: EdgeInsets.fromLTRB(16 + widget.leftInset, 0, 16, 24),
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
                          notifier.setItemNominal(item.nasabahId, nominal),
                      onMetode: (metode) =>
                          notifier.setItemMetode(item.nasabahId, metode),
                      onPotongan: (potongan) =>
                          notifier.setItemPotongan(item.nasabahId, potongan),
                      onRemove: () => notifier.removeItem(item.nasabahId),
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

  /// A warning shown under the field is easy to miss, so a Nominal that holds
  /// someone to their saldo is confirmed once more. It is never blocked: true
  /// when there is nothing to confirm or the pengurus says yes.
  Future<bool> _setujuSaldoKurang(JumlahUmum? jumlah) async {
    final kurang = _jumlahKurang(jumlah);
    if (jumlah == null || kurang == 0) return true;
    return showPencairanKonfirmasi(
      context,
      icon: Icons.warning_amber_rounded,
      judul: 'Terapkan Nominal ${rupiah(jumlah.nilai.floor())}?',
      pesan: _pesanKurang(kurang, jumlah),
      // Who is affected, by name and saldo, however many they are.
      isi: _DaftarSaldoKurang(
        items: [
          for (final item in _items)
            if (jumlah.melebihiSaldo(item.saldo)) item,
        ],
      ),
      jawaban: const KonfirmasiJawaban('Ya, terapkan'),
      nada: KonfirmasiNada.peringatan,
    );
  }

  Future<void> _terapkan() async {
    final jumlah = _jumlahBerubah ? _jumlah : null;
    if (!await _setujuSaldoKurang(jumlah) || !mounted) return;
    ProviderScope.containerOf(context, listen: false)
        .read(draftEditorProvider.notifier)
        .terapkanUmum(
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

  /// How many nasabah [jumlah] would hold to their saldo.
  int _jumlahKurang(JumlahUmum? jumlah) => jumlah == null
      ? 0
      : _items.where((i) => jumlah.melebihiSaldo(i.saldo)).length;

  static String _pesanKurang(int kurang, JumlahUmum jumlah) =>
      '$kurang nasabah saldonya di bawah ${rupiah(jumlah.nilai.floor())}. '
      'Mereka dicairkan seluruh saldonya.';

  /// A fixed rupiah stops at each saldo; says how many it stops for, so a
  /// pengurus is not surprised. A warning only: they are still paid.
  List<Widget> _saldoKurang(JumlahUmum? jumlah) {
    final kurang = _jumlahKurang(jumlah);
    if (jumlah == null || kurang == 0) return const [];
    return [
      const SizedBox(height: 8),
      Text(
        _pesanKurang(kurang, jumlah),
        key: const Key('jumlah-saldo-kurang'),
        style: AppTextStyle.small.copyWith(color: AppColors.warning),
      ),
    ];
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
          ..._saldoKurang(_jumlah ?? _jumlahTersimpan),
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
          AppButton(
            key: const Key('terapkan-umum'),
            label: 'Terapkan',
            size: AppButtonSize.compact,
            onPressed: _siap ? _terapkan : null,
          ),
        ],
      ),
    );
  }
}

/// Who a Nominal holds to their saldo, with that saldo: a short list that
/// scrolls once it grows past a few names.
class _DaftarSaldoKurang extends StatelessWidget {
  final List<EditorItem> items;

  const _DaftarSaldoKurang({required this.items});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const Key('daftar-saldo-kurang'),
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nasabahNama,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.small
                            .copyWith(color: AppColors.inkSoft),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Saldo ${rupiah(item.saldo)}',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final DraftEditorState state;
  final VoidCallback onSave;
  final VoidCallback onConfirm;

  /// One above the other, for the side panel, which is narrower than a phone.
  final bool tumpuk;

  const _BottomBar({
    required this.state,
    required this.onSave,
    required this.onConfirm,
    this.tumpuk = false,
  });

  @override
  Widget build(BuildContext context) {
    final canSave = state.canSave &&
        !state.isBusy &&
        (state.dirty || state.draftId == null);
    final simpan = PencairanActionButton(
      key: const Key('simpan'),
      label: 'Simpan Draft',
      icon: Icons.save_outlined,
      isLoading: state.phase == EditorPhase.saving,
      onPressed: canSave ? onSave : null,
    );
    final konfirmasi = PencairanActionButton(
      key: const Key('konfirmasi'),
      label: 'Konfirmasi Pembayaran',
      icon: Icons.check_circle_outline,
      filled: true,
      isLoading: state.phase == EditorPhase.confirming,
      onPressed: state.canConfirm ? onConfirm : null,
    );
    if (tumpuk) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [simpan, const SizedBox(height: 12), konfirmasi],
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(flex: 5, child: simpan),
            const SizedBox(width: 12),
            Expanded(flex: 6, child: konfirmasi),
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

  const _RingkasanBayar({
    required this.jumlah,
    required this.total,
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
            borderRadius: BorderRadius.circular(AppRadius.md),
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
            borderRadius: BorderRadius.circular(AppRadius.md),
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
      ],
    );
  }
}
