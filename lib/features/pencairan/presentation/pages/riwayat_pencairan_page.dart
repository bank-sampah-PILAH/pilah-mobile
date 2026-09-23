import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/riwayat_pencairan_filter.dart';
import '../blocs/riwayat_pencairan_cubit.dart';
import '../blocs/riwayat_pencairan_state.dart';

/// Opens the riwayat for one nasabah; without args it covers the whole bank.
class RiwayatPencairanArgs {
  final String nasabahId;
  final String nasabahNama;

  const RiwayatPencairanArgs({
    required this.nasabahId,
    required this.nasabahNama,
  });
}

class RiwayatPencairanPage extends StatelessWidget {
  static const route = '/riwayat-pencairan';

  final RiwayatPencairanArgs? args;

  const RiwayatPencairanPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<RiwayatPencairanCubit>(),
      child: RiwayatPencairanView(
        nasabahId: args?.nasabahId,
        nasabahNama: args?.nasabahNama,
      ),
    );
  }
}

class RiwayatPencairanView extends StatefulWidget {
  final String? nasabahId;
  final String? nasabahNama;
  final DateTime Function() now;

  const RiwayatPencairanView({
    super.key,
    this.nasabahId,
    this.nasabahNama,
    this.now = DateTime.now,
  });

  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  State<RiwayatPencairanView> createState() => _RiwayatPencairanViewState();
}

class _RiwayatPencairanViewState extends State<RiwayatPencairanView> {
  /// The backend ignores a `search` shorter than this and returns everything,
  /// so the screen refuses to send one rather than lying about the result.
  static const _minSearchLength = 2;

  final _searchController = TextEditingController();
  String? _searchError;

  bool get _perNasabah => widget.nasabahId != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final search = value.trim();
    if (search.isNotEmpty && search.length < _minSearchLength) {
      setState(() => _searchError = 'Minimal 2 huruf');
      return;
    }
    setState(() => _searchError = null);
    context.read<RiwayatPencairanCubit>().setSearch(search);
  }

  void _clearSearch() {
    _searchController.clear();
    _submitSearch('');
  }

  @override
  void initState() {
    super.initState();
    // One nasabah: their whole history. Whole bank: this month by default.
    context.read<RiwayatPencairanCubit>().load(
          _perNasabah
              ? RiwayatPencairanFilter(nasabahId: widget.nasabahId)
              : const RiwayatPencairanFilter(periode: RiwayatPeriode.bulanIni),
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = _perNasabah
        ? 'Riwayat Pencairan · ${widget.nasabahNama ?? ''}'
        : 'Riwayat Pencairan';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BlocBuilder<RiwayatPencairanCubit, RiwayatPencairanState>(
        builder: (context, state) {
          final cubit = context.read<RiwayatPencairanCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_perNasabah)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    key: const Key('riwayat-search'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitSearch,
                    decoration: InputDecoration(
                      hintText: 'Cari nama nasabah',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _searchError,
                      // Shown only while a search is actually applied, so the
                      // chips are never quietly narrowed by a stale term.
                      suffixIcon: state.filter.search.isEmpty
                          ? null
                          : IconButton(
                              key: const Key('riwayat-search-clear'),
                              icon: const Icon(Icons.close),
                              tooltip: 'Hapus pencarian',
                              onPressed: _clearSearch,
                            ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final periode in RiwayatPeriode.values)
                      ChoiceChip(
                        label: Text(periode.label),
                        selected: state.filter.periode == periode,
                        onSelected: (_) => cubit.setPeriode(periode),
                      ),
                  ],
                ),
              ),
              Expanded(child: _body(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, RiwayatPencairanState state) {
    if (state.status == RiwayatStatus.failure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage ?? 'Gagal memuat riwayat'),
            TextButton(
              onPressed: () =>
                  context.read<RiwayatPencairanCubit>().load(state.filter),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return state.status == RiwayatStatus.loaded
          ? const Center(child: Text('Belum ada pencairan'))
          : const Center(child: CircularProgressIndicator());
    }

    final today = widget.now();
    final children = <Widget>[];
    String? lastHeader;
    for (final item in state.items) {
      final header = _dayHeader(item.tanggal, today);
      if (header != lastHeader) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(header, style: AppTextStyle.small),
        ));
        lastHeader = header;
      }
      children.add(_RiwayatItem(item: item));
    }
    return ListView(children: children);
  }

  String _dayHeader(DateTime? tanggal, DateTime today) {
    if (tanggal == null) return 'LAINNYA';
    final diff = DateUtils.dateOnly(today)
        .difference(DateUtils.dateOnly(tanggal))
        .inDays;
    if (diff <= 0) return 'HARI INI';
    if (diff == 1) return 'KEMARIN';
    return '$diff HARI LALU';
  }
}

String _time(DateTime? tanggal) {
  if (tanggal == null) return '-';
  final h = tanggal.hour.toString().padLeft(2, '0');
  final m = tanggal.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _statusLabel(String status) =>
    status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1);

class _RiwayatItem extends StatelessWidget {
  final Pencairan item;

  const _RiwayatItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _DetailPencairanSheet(item: item),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nasabahNama, style: AppTextStyle.title1),
                  const SizedBox(height: 2),
                  Text(
                    '${item.metode.label} • ${_time(item.tanggal)}',
                    style: AppTextStyle.small,
                  ),
                  if (item.keterangan.isNotEmpty)
                    Text(item.keterangan, style: AppTextStyle.small),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${formatRupiahId(item.nominal)}',
                  style: AppTextStyle.title1.copyWith(
                    color: RiwayatPencairanView.emeraldPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_statusLabel(item.status), style: AppTextStyle.small),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPencairanSheet extends StatelessWidget {
  final Pencairan item;

  const _DetailPencairanSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final tanggal = item.tanggal;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Detail Pencairan', style: AppTextStyle.title1),
          const SizedBox(height: 16),
          _row('Nasabah', item.nasabahNama),
          _row('Nominal', 'Rp ${formatRupiahId(item.nominal)}'),
          _row('Metode', item.metode.label),
          _row(
            'Tanggal',
            tanggal == null
                ? '-'
                : '${formatTanggalId(tanggal)}, ${_time(tanggal)}',
          ),
          _row('Status', _statusLabel(item.status)),
          _row('Keterangan', item.keterangan.isEmpty ? '-' : item.keterangan),
          _row('Saldo sebelum', 'Rp ${formatRupiahId(item.saldoSebelum)}'),
          _row('Saldo sesudah', 'Rp ${formatRupiahId(item.saldoSesudah)}'),
          _row(
            'Dicatat oleh',
            item.dicatatOlehNama.isEmpty ? '-' : item.dicatatOlehNama,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyle.small),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyle.title1,
              ),
            ),
          ],
        ),
      );
}
