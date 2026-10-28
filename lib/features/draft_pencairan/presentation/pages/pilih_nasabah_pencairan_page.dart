import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

import '../../domain/model/draft_pencairan.dart';
import '../states/pilih_nasabah_state.dart';
import '../providers/pilih_nasabah_provider.dart';
import '../widgets/draft_format.dart';
import '../widgets/pencairan_sort_button.dart';
import '../widgets/saldo_min_sheet.dart';
import '../widgets/pencairan_ui.dart';
import 'draft_list_page.dart';

/// First step of a pencairan: choose who is paid. Search, sort, filters and
/// picking in bulk make a long list manageable; picks survive them all.
class PilihNasabahPencairanPage extends StatelessWidget {
  static const route = DraftListPage.routePilih;

  const PilihNasabahPencairanPage({super.key});

  @override
  Widget build(BuildContext context) => const PilihNasabahView();
}

class PilihNasabahView extends ConsumerStatefulWidget {
  /// Pause after the last keystroke before the search is sent, so a word does
  /// not cost one request per letter.
  static const jedaCari = Duration(milliseconds: 300);

  const PilihNasabahView({super.key});

  @override
  ConsumerState<PilihNasabahView> createState() => _PilihNasabahViewState();
}

class _PilihNasabahViewState extends ConsumerState<PilihNasabahView> {
  Timer? _jeda;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pilihNasabahProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _jeda?.cancel();
    super.dispose();
  }

  void _onSearch(String text) {
    _jeda?.cancel();
    _jeda = Timer(PilihNasabahView.jedaCari, () {
      if (mounted) {
        ref.read(pilihNasabahProvider.notifier).setSearch(text.trim());
      }
    });
  }

  Future<void> _askSaldoMin() async {
    final state = ref.read(pilihNasabahProvider);
    final saldoMin = await showSaldoMinSheet(
      context,
      kandidat: state.kandidat,
      awal: state.saldoMin,
    );
    if (saldoMin != null && mounted) {
      ref.read(pilihNasabahProvider.notifier).setSaldoMin(saldoMin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pilihNasabahProvider);
    final notifier = ref.read(pilihNasabahProvider.notifier);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // A list of names and saldo is read row by row, so a desktop window
        // keeps it to a form's column, and the footer below matches it. The
        // list itself scrolls across the body, so its scrollbar is at the edge.
        child: ContentFrame(
          maxWidth: LayoutBreakpoint.formMaxWidth,
          child: Column(
            children: [
              const ContentInset(
                child: AppBackHeader(
                    backKey: Key('kembali'), title: 'Pilih Nasabah'),
              ),
              ContentInset(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomSearchField(
                          key: const Key('cari-kandidat'),
                          hintText: 'Cari nama, kode, atau nomor HP',
                          onChanged: _onSearch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PencairanSortButton<KandidatSortField>(
                        buttonKey: const Key('urutkan-kandidat'),
                        itemKeyPrefix: 'urut-kandidat-',
                        fields: KandidatSortField.values,
                        labelOf: (field) => field.label,
                        current: state.urutan.field,
                        ascending: state.urutan.ascending,
                        onSort: notifier.setSortField,
                      ),
                    ],
                  ),
                ),
              ),
              ContentInset(
                  child: _Filters(
                      state: state,
                      notifier: notifier,
                      onSaldoMin: _askSaldoMin)),
              ContentInset(child: _BulkRow(state: state, notifier: notifier)),
              Expanded(child: _List(state: state, notifier: notifier)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _Footer(state: state),
    );
  }
}

/// The filter pills, left-aligned under the search field and green when on,
/// each with how many nasabah it holds. The minimum saldo opens its amount
/// dialog and then reads like the rest, as "Saldo \u2265 Rp 200.000".
class _Filters extends StatelessWidget {
  final PilihNasabahState state;
  final PilihNasabahNotifier notifier;
  final VoidCallback onSaldoMin;

  const _Filters({
    required this.state,
    required this.notifier,
    required this.onSaldoMin,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(Key key, PilihFilter filter) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PencairanChip(
            key: key,
            label: filter.label,
            count: state.jumlah(filter),
            selected: state.filter == filter,
            onTap: () => notifier.setFilter(filter),
          ),
        );
    final aktif = state.saldoMin > 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          chip(const Key('pf-semua'), PilihFilter.semua),
          chip(const Key('pf-terpilih'), PilihFilter.terpilih),
          chip(const Key('pf-belum'), PilihFilter.belumDipilih),
          chip(const Key('pf-kosong'), PilihFilter.saldoKosong),
          PencairanChip(
            key: const Key('pf-saldo'),
            label: aktif
                ? 'Saldo \u2265 ${rupiah(state.saldoMin)}'
                : 'Saldo minimal',
            selected: aktif,
            onTap: aktif ? () => notifier.setSaldoMin(0) : onSaldoMin,
          ),
        ],
      ),
    );
  }
}

/// One checkbox for everyone shown, with the two other bulk actions beside it.
/// They act on what the filters leave on screen, and never on someone without
/// saldo.
class _BulkRow extends StatelessWidget {
  final PilihNasabahState state;
  final PilihNasabahNotifier notifier;

  const _BulkRow({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final dapat = state.dapatDipilih.length;
    final nilai = switch (state.pilihanTampil) {
      PilihanTampil.tidakAda => false,
      PilihanTampil.sebagian => null,
      PilihanTampil.semua => true,
    };
    final teks = AppTextStyle.small.copyWith(
      color: AppColors.greenDark,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: const Key('pilih-tampil'),
              onTap: dapat == 0 ? null : notifier.pilihTampil,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Row(
                children: [
                  IgnorePointer(
                    child: Checkbox(
                      tristate: true,
                      value: nilai,
                      // Never fires: IgnorePointer, the row's InkWell taps.
                      onChanged: (_) {}, // coverage:ignore-line
                      activeColor: AppColors.greenDark,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Pilih semua ($dapat)',
                      style: AppTextStyle.small
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            key: const Key('balikkan'),
            onPressed: notifier.balikkan,
            child: Text('Balikkan', style: teks),
          ),
          TextButton(
            key: const Key('kosongkan'),
            onPressed: notifier.kosongkan,
            child: Text('Kosongkan', style: teks),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  final PilihNasabahState state;
  final PilihNasabahNotifier notifier;

  const _List({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case PilihStatus.loading:
        return ListView(
          padding: ContentFrame.insetOf(context)
              .add(const EdgeInsets.symmetric(horizontal: 16)),
          children: List.generate(5, (_) => const SkeletonListItem()),
        );
      case PilihStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'Gagal memuat nasabah',
                  style: AppTextStyle.small),
              TextButton(
                  onPressed: notifier.load, child: const Text('Coba lagi')),
            ],
          ),
        );
      case PilihStatus.loaded:
        return _kosongAtauDaftar(context, notifier);
    }
  }

  /// An explanation when there is nothing to pick, otherwise the rows.
  Widget _kosongAtauDaftar(
      BuildContext context, PilihNasabahNotifier notifier) {
    if (state.kandidat.isEmpty) {
      return EmptyView(
        title: state.search.isEmpty
            ? 'Tidak ada nasabah yang dapat dicairkan'
            : 'Tidak ada nasabah yang cocok',
        subtitle: 'Nasabah aktif yang memiliki saldo akan muncul di sini.',
        icon: Icons.people_outline,
      );
    }
    if (state.tampil.isEmpty) {
      return const EmptyView(
        title: 'Belum ada nasabah pada filter ini',
        subtitle: 'Ganti filter untuk melihat nasabah lainnya.',
        icon: Icons.filter_list_off,
      );
    }
    return ListView.separated(
      padding: ContentFrame.insetOf(context)
          .add(const EdgeInsets.fromLTRB(16, 8, 16, 16)),
      itemCount: state.tampil.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final kandidat = state.tampil[index];
        return _KandidatRow(
          kandidat: kandidat,
          dipilih: state.selectedIds.contains(kandidat.id),
          onTap: () => notifier.toggle(kandidat.id),
        );
      },
    );
  }
}

/// One nasabah: a card to tap. Without saldo it is dimmed and cannot be picked.
class _KandidatRow extends StatelessWidget {
  final Kandidat kandidat;
  final bool dipilih;
  final VoidCallback onTap;

  const _KandidatRow({
    required this.kandidat,
    required this.dipilih,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saldo = kandidat.kosong ? 'Saldo kosong' : rupiah(kandidat.saldo);
    final kartu = PencairanCard.shadow(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderColor: dipilih ? AppColors.greenDark : null,
      child: Row(
        children: [
          IgnorePointer(
            child: Checkbox(
              value: dipilih,
              onChanged: kandidat.kosong ? null : (_) {},
              activeColor: AppColors.greenDark,
            ),
          ),
          PencairanAvatar(
            key: Key('avatar-${kandidat.id}'),
            nama: kandidat.nama,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kandidat.nama, style: AppTextStyle.headline3),
                Text('${kandidat.kode} \u00b7 $saldo',
                    style: AppTextStyle.small),
              ],
            ),
          ),
        ],
      ),
    );
    return InkWell(
      key: Key('kandidat-${kandidat.id}'),
      onTap: kandidat.kosong ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      // Dimmed: it is here to be seen, not to be picked.
      child: kandidat.kosong ? Opacity(opacity: 0.5, child: kartu) : kartu,
    );
  }
}

class _Footer extends StatelessWidget {
  final PilihNasabahState state;

  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    final terpilih = state.terpilih;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: ContentBounds(
          maxWidth: LayoutBreakpoint.formMaxWidth,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${state.jumlahTerpilih} dipilih',
                          style: AppTextStyle.headline3),
                      Text('Total saldo ${rupiah(state.saldoTerpilih)}',
                          style: AppTextStyle.small),
                      if (state.kelebihan)
                        Text('Maksimal 1.000 nasabah per draft',
                            style: AppTextStyle.small
                                .copyWith(color: AppColors.danger)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: AppButton(
                    key: const Key('lanjut'),
                    label: 'Lanjut',
                    onPressed: terpilih.isEmpty || state.kelebihan
                        ? null
                        : () => context.pop(terpilih),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
