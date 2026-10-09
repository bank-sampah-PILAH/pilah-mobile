import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
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
              _FilterChips(selected: state.filter),
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

class _FilterChips extends StatelessWidget {
  final DraftStatus? selected;

  const _FilterChips({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DraftListCubit>();
    Widget chip(Key key, String label, DraftStatus? value) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PencairanChip(
            key: key,
            label: label,
            selected: selected == value,
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
        return AppRefreshIndicator(
          onRefresh: cubit.load,
          child: drafts.isEmpty
              ? const EmptyView(
                  title: 'Belum ada draft pencairan',
                  subtitle: 'Buat pencairan untuk satu atau banyak nasabah.',
                  icon: Icons.payments_outlined,
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: drafts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _DraftCard(
                    draft: drafts[index],
                    onTap: () => onOpen(
                      context,
                      DraftListPage.routeEditor,
                      extra: DraftEditorArgs.lanjutkan(drafts[index].id),
                    ),
                    onCancel: () => _batalkan(context, drafts[index]),
                  ),
                ),
        );
    }
  }
}

Future<void> _batalkan(BuildContext context, DraftRingkasan draft) async {
  final cubit = context.read<DraftListCubit>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Batalkan draft?'),
      content: Text(
        '"${draft.nama}" tidak akan dibayarkan. Saldo nasabah tidak berubah.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Kembali'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Ya, batalkan'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final error = await cubit.batalkan(draft.id);
  if (error != null && context.mounted) {
    AppNotification.showError(context, title: 'Gagal', message: error);
  }
}

class _DraftCard extends StatelessWidget {
  final DraftRingkasan draft;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  const _DraftCard({
    required this.draft,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (draft.dibuatOlehNama.isNotEmpty) draft.dibuatOlehNama,
      waktu(draft.createdAt),
    ].where((part) => part.isNotEmpty).join(' · ');
    return InkWell(
      key: Key('draft-${draft.id}'),
      onTap: onTap,
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
                if (draft.status == DraftStatus.draft)
                  IconButton(
                    key: Key('batalkan-${draft.id}'),
                    tooltip: 'Batalkan draft',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                    onPressed: onCancel,
                    icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${draft.jumlahItem} nasabah · ${rupiah(draft.totalDibayar)}',
              style: AppTextStyle.small.copyWith(fontWeight: FontWeight.w600),
            ),
            if (draft.totalPotongan > 0)
              Text(
                'Potongan ${rupiah(draft.totalPotongan)}',
                style: AppTextStyle.extraSmall,
              ),
            if (meta.isNotEmpty) Text(meta, style: AppTextStyle.extraSmall),
          ],
        ),
      ),
    );
  }
}
