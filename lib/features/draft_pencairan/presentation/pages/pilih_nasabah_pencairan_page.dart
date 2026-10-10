import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/draft_pencairan.dart';
import '../blocs/pilih_nasabah_cubit.dart';
import '../blocs/pilih_nasabah_state.dart';
import '../widgets/draft_format.dart';
import '../widgets/pencairan_sort_button.dart';
import '../widgets/saldo_min_sheet.dart';
import '../widgets/pencairan_ui.dart';
import 'draft_editor_args.dart';
import 'draft_list_page.dart';

/// First step of a pencairan: choose who is paid. Search, sort, filters and
/// picking in bulk make a long list manageable; picks survive them all.
class PilihNasabahPencairanPage extends StatelessWidget {
  static const route = DraftListPage.routePilih;

  const PilihNasabahPencairanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<PilihNasabahCubit>()..load(),
      child: const PilihNasabahView(),
    );
  }
}

class PilihNasabahView extends StatefulWidget {
  /// Pause after the last keystroke before the search is sent, so a word does
  /// not cost one request per letter.
  static const jedaCari = Duration(milliseconds: 300);

  const PilihNasabahView({super.key});

  @override
  State<PilihNasabahView> createState() => _PilihNasabahViewState();
}

class _PilihNasabahViewState extends State<PilihNasabahView> {
  Timer? _jeda;

  @override
  void dispose() {
    _jeda?.cancel();
    super.dispose();
  }

  void _onSearch(String text) {
    _jeda?.cancel();
    _jeda = Timer(PilihNasabahView.jedaCari, () {
      if (mounted) context.read<PilihNasabahCubit>().setSearch(text.trim());
    });
  }

  Future<void> _askSaldoMin() async {
    final cubit = context.read<PilihNasabahCubit>();
    final saldoMin = await showSaldoMinSheet(
      context,
      kandidat: cubit.state.kandidat,
      awal: cubit.state.saldoMin,
    );
    if (saldoMin != null) cubit.setSaldoMin(saldoMin);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<PilihNasabahCubit, PilihNasabahState>(
          builder: (context, state) => Column(
            children: [
              const PencairanHeader(title: 'Pilih Nasabah'),
              Padding(
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
                      onSort: cubit.setSortField,
                    ),
                  ],
                ),
              ),
              _Filters(state: state, onSaldoMin: _askSaldoMin),
              _BulkRow(state: state),
              Expanded(child: _List(state: state)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<PilihNasabahCubit, PilihNasabahState>(
        builder: (context, state) => _Footer(state: state),
      ),
    );
  }
}

/// The filter pills, left-aligned under the search field and green when on,
/// each with how many nasabah it holds. The minimum saldo opens its amount
/// dialog and then reads like the rest, as "Saldo \u2265 Rp 200.000".
class _Filters extends StatelessWidget {
  final PilihNasabahState state;
  final VoidCallback onSaldoMin;

  const _Filters({required this.state, required this.onSaldoMin});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
    Widget chip(Key key, PilihFilter filter) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PencairanChip(
            key: key,
            label: filter.label,
            count: state.jumlah(filter),
            selected: state.filter == filter,
            onTap: () => cubit.setFilter(filter),
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
            onTap: aktif ? () => cubit.setSaldoMin(0) : onSaldoMin,
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

  const _BulkRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
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
              onTap: dapat == 0 ? null : cubit.pilihTampil,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  IgnorePointer(
                    child: Checkbox(
                      tristate: true,
                      value: nilai,
                      onChanged: (_) {},
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
            onPressed: cubit.balikkan,
            child: Text('Balikkan', style: teks),
          ),
          TextButton(
            key: const Key('kosongkan'),
            onPressed: cubit.kosongkan,
            child: Text('Kosongkan', style: teks),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  final PilihNasabahState state;

  const _List({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
    switch (state.status) {
      case PilihStatus.loading:
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: List.generate(5, (_) => const SkeletonListItem()),
        );
      case PilihStatus.failure:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'Gagal memuat nasabah',
                  style: AppTextStyle.small),
              TextButton(onPressed: cubit.load, child: const Text('Coba lagi')),
            ],
          ),
        );
      case PilihStatus.loaded:
        if (state.tampil.isEmpty && state.kandidat.isNotEmpty) {
          return const EmptyView(
            title: 'Belum ada nasabah pada filter ini',
            subtitle: 'Ganti filter untuk melihat nasabah lainnya.',
            icon: Icons.filter_list_off,
          );
        }
        if (state.kandidat.isEmpty) {
          return EmptyView(
            title: state.search.isEmpty
                ? 'Tidak ada nasabah yang dapat dicairkan'
                : 'Tidak ada nasabah yang cocok',
            subtitle: 'Nasabah aktif yang memiliki saldo akan muncul di sini.',
            icon: Icons.people_outline,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: state.tampil.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final kandidat = state.tampil[index];
            final dipilih = state.selectedIds.contains(kandidat.id);
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
                        Text(
                          kandidat.kosong
                              ? '${kandidat.kode} \u00b7 Saldo kosong'
                              : '${kandidat.kode} \u00b7 ${rupiah(kandidat.saldo)}',
                          style: AppTextStyle.small,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
            return InkWell(
              key: Key('kandidat-${kandidat.id}'),
              onTap: kandidat.kosong ? null : () => cubit.toggle(kandidat.id),
              borderRadius: BorderRadius.circular(16),
              // Dimmed: it is here to be seen, not to be picked.
              child:
                  kandidat.kosong ? Opacity(opacity: 0.5, child: kartu) : kartu,
            );
          },
        );
    }
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
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
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
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: CustomPrimaryButton(
                  key: const Key('lanjut'),
                  title: 'Lanjut',
                  onPressed: terpilih.isEmpty
                      ? null
                      : () => context.pushReplacement(
                            DraftListPage.routeEditor,
                            extra: DraftEditorArgs.baru(terpilih),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
