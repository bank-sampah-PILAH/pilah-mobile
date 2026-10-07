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
import '../widgets/pencairan_ui.dart';
import 'draft_editor_args.dart';
import 'draft_list_page.dart';

/// First step of a pencairan: choose who is paid. Search, sort and quick
/// selects make a long list manageable; picks survive both.
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<PilihNasabahCubit, PilihNasabahState>(
          builder: (context, state) => Column(
            children: [
              PencairanHeader(
                title: 'Pilih Nasabah',
                actions: [
                  PopupMenuButton<KandidatUrutan>(
                    key: const Key('urutan'),
                    tooltip: 'Urutkan',
                    icon: Icon(Icons.sort, color: Colors.grey[800]),
                    initialValue: state.urutan,
                    onSelected: cubit.setUrutan,
                    itemBuilder: (_) => [
                      for (final urutan in KandidatUrutan.values)
                        PopupMenuItem(value: urutan, child: Text(urutan.label)),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomSearchField(
                  hintText: 'Cari nama, kode, atau nomor HP',
                  onChanged: _onSearch,
                ),
              ),
              const _QuickSelects(),
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

class _QuickSelects extends StatelessWidget {
  const _QuickSelects();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PencairanChip(
            key: const Key('pilih-semua'),
            label: 'Pilih semua',
            selected: false,
            onTap: cubit.pilihSemua,
          ),
          PencairanChip(
            key: const Key('kosongkan'),
            label: 'Kosongkan',
            selected: false,
            onTap: cubit.kosongkan,
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
          itemCount: state.kandidat.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final kandidat = state.kandidat[index];
            final dipilih = state.selectedIds.contains(kandidat.id);
            return InkWell(
              key: Key('kandidat-${kandidat.id}'),
              onTap: () => cubit.toggle(kandidat.id),
              borderRadius: BorderRadius.circular(16),
              child: PencairanCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderColor:
                    dipilih ? AppColors.greenDark : Colors.grey.shade200,
                child: Row(
                  children: [
                    IgnorePointer(
                      child: Checkbox(
                        value: dipilih,
                        onChanged: (_) {},
                        activeColor: AppColors.greenDark,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kandidat.nama, style: AppTextStyle.headline3),
                          Text(
                            '${kandidat.kode} · ${rupiah(kandidat.saldo)}',
                            style: AppTextStyle.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
