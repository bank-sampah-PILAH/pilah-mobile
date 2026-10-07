import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: Text('Pilih Nasabah', style: AppTextStyle.appBar),
      ),
      body: BlocBuilder<PilihNasabahCubit, PilihNasabahState>(
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomSearchField(
                      hintText: 'Cari nama, kode, atau nomor HP',
                      onChanged: _onSearch,
                    ),
                  ),
                  PopupMenuButton<KandidatUrutan>(
                    key: const Key('urutan'),
                    tooltip: 'Urutkan',
                    icon: const Icon(Icons.sort),
                    initialValue: state.urutan,
                    onSelected: cubit.setUrutan,
                    itemBuilder: (_) => [
                      for (final urutan in KandidatUrutan.values)
                        PopupMenuItem(value: urutan, child: Text(urutan.label)),
                    ],
                  ),
                ],
              ),
            ),
            const _QuickSelects(),
            Expanded(child: _List(state: state)),
            _Footer(state: state),
          ],
        ),
      ),
    );
  }
}

class _QuickSelects extends StatelessWidget {
  const _QuickSelects();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PilihNasabahCubit>();
    Widget chip(Key key, String label, VoidCallback onTap) => ActionChip(
          key: key,
          label: Text(label, style: AppTextStyle.small),
          backgroundColor: AppColors.greenLight,
          side: BorderSide.none,
          onPressed: onTap,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 0,
        children: [
          chip(const Key('pilih-semua'), 'Pilih semua', cubit.pilihSemua),
          chip(const Key('kosongkan'), 'Kosongkan', cubit.kosongkan),
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
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: state.kandidat.length,
          itemBuilder: (context, index) {
            final kandidat = state.kandidat[index];
            return CheckboxListTile(
              key: Key('kandidat-${kandidat.id}'),
              value: state.selectedIds.contains(kandidat.id),
              onChanged: (_) => cubit.toggle(kandidat.id),
              activeColor: AppColors.greenDark,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(kandidat.nama, style: AppTextStyle.headline3),
              subtitle: Text(
                '${kandidat.kode} · ${rupiah(kandidat.saldo)}',
                style: AppTextStyle.small,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
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
            ElevatedButton(
              key: const Key('lanjut'),
              onPressed: terpilih.isEmpty
                  ? null
                  : () => context.pushReplacement(
                        DraftListPage.routeEditor,
                        extra: DraftEditorArgs.baru(terpilih),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }
}
