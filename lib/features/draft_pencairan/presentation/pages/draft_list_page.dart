import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/draft_list_cubit.dart';
import '../blocs/draft_list_state.dart';
import '../widgets/draft_format.dart';
import '../widgets/draft_status_badge.dart';
import '../widgets/pencairan_konfirmasi_sheet.dart';
import '../widgets/pencairan_sort_button.dart';
import '../widgets/pencairan_ui.dart';
import 'draft_editor_args.dart';

/// The pencairan screen: saved drafts to resume, and the way to start a new one.
class DraftListPage extends StatelessWidget {
  static const route = '/draft-pencairan';
  static const routePilih = '/draft-pencairan/pilih';
  static const routeEditor = '/draft-pencairan/editor';

  const DraftListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<DraftListCubit>()..load(),
      child: const DraftListView(),
    );
  }
}

class DraftListView extends StatelessWidget {
  const DraftListView({super.key});

  Future<void> _open(BuildContext context, String route,
      {Object? extra}) async {
    final cubit = context.read<DraftListCubit>();
    await context.push<Object?>(route, extra: extra);
    // Whatever happened over there, the list may have changed.
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<DraftListCubit, DraftListState>(
          builder: (context, state) => Column(
            children: [
              PencairanHeader(
                title: 'Pencairan',
                actions: [
                  PencairanPopupMenu<String>(
                    key: const Key('menu-lainnya'),
                    onSelected: (_) => context.push(CatatPencairanPage.route),
                    entries: const [
                      PencairanMenuEntry(
                        key: Key('aksi-catat'),
                        value: 'catat',
                        label: 'Catat pencairan satu nasabah',
                        icon: Icons.edit_note,
                      ),
                    ],
                  ),
                ],
              ),
              const _SearchBar(),
              _FilterChips(state: state),
              Expanded(child: _Body(state: state, onOpen: _open)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'draft_list_fab',
        backgroundColor: AppColors.greenDark,
        foregroundColor: Colors.white,
        onPressed: () => _open(context, DraftListPage.routePilih),
        icon: const Icon(Icons.add),
        label: const Text('Buat Pencairan'),
      ),
    );
  }
}

/// The search field, kept in step with the cubit so that clearing the search
/// from the empty state empties the text too.
class _SearchBar extends StatefulWidget {
  const _SearchBar();

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftListCubit>();
    return BlocListener<DraftListCubit, DraftListState>(
      listenWhen: (a, b) => a.query != b.query,
      listener: (context, state) {
        if (_controller.text != state.query) _controller.text = state.query;
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: CustomSearchField(
                key: const Key('cari-draft'),
                controller: _controller,
                hintText: 'Cari nama, pembuat, atau tanggal',
                onChanged: cubit.setQuery,
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<DraftListCubit, DraftListState>(
              buildWhen: (a, b) => a.urutan != b.urutan,
              builder: (context, state) => PencairanSortButton<DraftSortField>(
                buttonKey: const Key('urutkan-draft'),
                itemKeyPrefix: 'urut-draft-',
                fields: DraftSortField.values,
                labelOf: (field) => field.label,
                current: state.urutan.field,
                ascending: state.urutan.ascending,
                onSort: cubit.setUrutan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final DraftListState state;

  const _FilterChips({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftListCubit>();
    Widget chip(Key key, String label, DraftStatus? value) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PencairanChip(
            key: key,
            label: label,
            selected: state.filter == value,
            count: state.status == DraftListStatus.loaded
                ? state.jumlah(value)
                : null,
            onTap: () => cubit.setFilter(value),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        chip(const Key('filter-semua'), 'Semua', null),
        chip(const Key('filter-draft'), 'Draft', DraftStatus.draft),
        chip(const Key('filter-dikonfirmasi'), 'Dikonfirmasi',
            DraftStatus.dikonfirmasi),
        chip(const Key('filter-dibatalkan'), 'Dibatalkan',
            DraftStatus.dibatalkan),
      ]),
    );
  }
}

class _Body extends StatelessWidget {
  final DraftListState state;
  final Future<void> Function(BuildContext, String, {Object? extra}) onOpen;

  const _Body({required this.state, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftListCubit>();
    switch (state.status) {
      case DraftListStatus.loading:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(4, (_) => const SkeletonListItem()),
        );
      case DraftListStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'Gagal memuat draft',
                  style: AppTextStyle.small),
              TextButton(onPressed: cubit.load, child: const Text('Coba lagi')),
            ],
          ),
        );
      case DraftListStatus.loaded:
        final drafts = state.tampil;
        final dicari = state.query.trim().isNotEmpty;
        if (drafts.isEmpty && dicari) {
          return AppRefreshIndicator(
            onRefresh: cubit.load,
            child: _TidakAdaHasil(
              query: state.query.trim(),
              onClear: () => cubit.setQuery(''),
            ),
          );
        }
        final entries = _susun(drafts, state.urutan);
        return AppRefreshIndicator(
          onRefresh: cubit.load,
          child: drafts.isEmpty
              ? const EmptyView(
                  title: 'Belum ada draft pencairan',
                  subtitle: 'Buat pencairan untuk satu atau banyak nasabah.',
                  icon: Icons.payments_outlined,
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    if (entry is String) return _KelompokHeader(entry);
                    final draft = entry as DraftRingkasan;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DraftCard(
                        draft: draft,
                        onTap: () => onOpen(
                          context,
                          DraftListPage.routeEditor,
                          extra: DraftEditorArgs.lanjutkan(draft.id),
                        ),
                        onCancel: () => _batalkan(context, draft),
                      ),
                    );
                  },
                ),
        );
    }
  }
}

/// The list as drawn: a heading before the first draft of each date group, in
/// the time orders, and the drafts alone otherwise.
List<Object> _susun(List<DraftRingkasan> drafts, DraftSort urutan) {
  if (!urutan.perTanggal) return drafts;
  final entries = <Object>[];
  String? terakhir;
  for (final draft in drafts) {
    final label = labelKelompok(draft.createdAt);
    if (label != terakhir) {
      entries.add(label);
      terakhir = label;
    }
    entries.add(draft);
  }
  return entries;
}

class _KelompokHeader extends StatelessWidget {
  final String label;

  const _KelompokHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Text(
          label,
          style: AppTextStyle.extraSmall.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _TidakAdaHasil extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _TidakAdaHasil({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      "Tidak ada pencairan untuk '$query'",
                      textAlign: TextAlign.center,
                      style: AppTextStyle.small,
                    ),
                    TextButton(
                      key: const Key('hapus-pencarian'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.greenDark),
                      onPressed: onClear,
                      child: const Text('Hapus pencarian'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

Future<void> _batalkan(BuildContext context, DraftRingkasan draft) async {
  final cubit = context.read<DraftListCubit>();
  final ok = await showPencairanKonfirmasi(
    context,
    icon: Icons.delete_outline,
    judul: 'Batalkan draft?',
    pesan: 'Draft ini tidak akan dibayarkan. Saldo nasabah tidak berubah.',
    isi: Container(
      key: const Key('batalkan-ringkasan'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft.nama,
              style: AppTextStyle.small.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            '${draft.jumlahItem} nasabah \u00b7 ${rupiah(draft.totalDibayar)}',
            style: AppTextStyle.extraSmall,
          ),
        ],
      ),
    ),
    ya: 'Ya, batalkan',
    tidak: 'Kembali',
    nada: KonfirmasiNada.bahaya,
  );
  if (!ok) return;
  final error = await cubit.batalkan(draft.id);
  if (error != null && context.mounted) {
    AppNotification.showError(context, title: 'Gagal', message: error);
  }
}

class _DraftCard extends StatefulWidget {
  final DraftRingkasan draft;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  const _DraftCard({
    required this.draft,
    required this.onTap,
    required this.onCancel,
  });

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return InkWell(
      key: Key('draft-${draft.id}'),
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: PencairanCard.shadow(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.nama,
                    style: AppTextStyle.headline3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                DraftStatusBadge(status: draft.status),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text('${draft.jumlahItem} nasabah',
                    style: AppTextStyle.extraSmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total dibayar',
                          style: AppTextStyle.extraSmall
                              .copyWith(color: Colors.grey[700])),
                      Text(
                        rupiah(draft.totalDibayar),
                        style: AppTextStyle.headline3.copyWith(
                          color: AppColors.greenDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('ekspan-${draft.id}'),
                  tooltip: _expanded ? 'Sembunyikan rincian' : 'Lihat rincian',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              _Rincian(draft: draft),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.grey.shade200),
            ),
            _Footer(draft: draft, onCancel: widget.onCancel),
          ],
        ),
      ),
    );
  }
}

/// What the total paid is made of: the saldo and what comes off it.
class _Rincian extends StatelessWidget {
  final DraftRingkasan draft;

  const _Rincian({required this.draft});

  @override
  Widget build(BuildContext context) {
    Widget row(Key key, String label, String value, {Color? color}) => Row(
          key: key,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyle.small),
            Text(
              value,
              style: AppTextStyle.small.copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          row(Key('total-saldo-${draft.id}'), 'Total saldo',
              rupiah(draft.totalNominal)),
          const SizedBox(height: 8),
          row(
            Key('total-potongan-${draft.id}'),
            'Potongan',
            draft.totalPotongan > 0
                ? '\u2212 ${rupiah(draft.totalPotongan)}'
                : rupiah(0),
            color: draft.totalPotongan > 0 ? AppColors.statOrange : null,
          ),
        ],
      ),
    );
  }
}

/// Who made the draft and when, with the way to throw it away at the far end.
class _Footer extends StatelessWidget {
  final DraftRingkasan draft;
  final VoidCallback onCancel;

  const _Footer({required this.draft, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyle.extraSmall.copyWith(color: Colors.grey[700]);
    final time = waktu(draft.createdAt);
    return Row(
      key: Key('footer-${draft.id}'),
      children: [
        if (draft.dibuatOlehNama.isNotEmpty) ...[
          PencairanAvatar(nama: draft.dibuatOlehNama, size: 32),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (draft.dibuatOlehNama.isNotEmpty)
                Text(
                  draft.dibuatOlehNama,
                  style:
                      AppTextStyle.small.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (time.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(time,
                          style: muted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (draft.status == DraftStatus.draft)
          IconButton(
            key: Key('batalkan-${draft.id}'),
            tooltip: 'Batalkan draft',
            visualDensity: VisualDensity.compact,
            onPressed: onCancel,
            icon: Icon(Icons.delete_outline, color: Colors.red[700]),
          ),
      ],
    );
  }
}
