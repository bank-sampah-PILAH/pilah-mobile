import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/model/riwayat_pencairan_filter.dart';
import '../blocs/riwayat_pencairan_cubit.dart';
import '../blocs/riwayat_pencairan_state.dart';

class RiwayatPencairanNasabahPage extends StatelessWidget {
  const RiwayatPencairanNasabahPage({super.key});

  static const route = '/nasabah/riwayat-pencairan';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di<RiwayatPencairanCubit>(),
      child: const RiwayatPencairanNasabahView(),
    );
  }
}

class RiwayatPencairanNasabahView extends StatefulWidget {
  const RiwayatPencairanNasabahView({super.key});

  @override
  State<RiwayatPencairanNasabahView> createState() =>
      _RiwayatPencairanNasabahViewState();
}

class _RiwayatPencairanNasabahViewState
    extends State<RiwayatPencairanNasabahView> {
  @override
  void initState() {
    super.initState();
    context.read<RiwayatPencairanCubit>().load(
          const RiwayatPencairanFilter(periode: RiwayatPeriode.semua),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pencairan')),
      body: AppRefreshIndicator(
        onRefresh: () {
          final cubit = context.read<RiwayatPencairanCubit>();
          return cubit.load(cubit.state.filter);
        },
        child: BlocBuilder<RiwayatPencairanCubit, RiwayatPencairanState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (state.status == RiwayatStatus.failure &&
                    state.items.isEmpty) {
                  return _messageList(
                    constraints.maxHeight,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.errorMessage ?? 'Gagal memuat riwayat',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<RiwayatPencairanCubit>()
                              .load(state.filter),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  final message = state.status == RiwayatStatus.loaded
                      ? const Text('Belum ada riwayat pencairan')
                      : const CircularProgressIndicator();
                  return _messageList(constraints.maxHeight, message);
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: state.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _PencairanNasabahCard(item: state.items[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _messageList(double height, Widget message) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: height,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: message,
              ),
            ),
          ),
        ],
      );
}

class _PencairanNasabahCard extends StatelessWidget {
  final Pencairan item;

  const _PencairanNasabahCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final tanggal = item.tanggal;
    final bankNama =
        item.bankSampahNama.isEmpty ? 'Bank Sampah' : item.bankSampahNama;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ActivityItem(
        avatarText: _initialsOf(bankNama),
        avatarColor: AppColors.greenLight,
        avatarTextColor: AppColors.greenDark,
        title: bankNama,
        subtitleLines: [
          item.metode.label,
          if (item.keterangan.isNotEmpty) item.keterangan,
        ],
        amount: 'Rp ${formatRupiahId(item.nominal)}',
        trailingCaptions: [
          tanggal == null ? '-' : formatTanggalId(tanggal),
          if (tanggal != null) _time(tanggal),
        ],
        badge: item.diperbarui ? 'Diperbarui' : null,
      ),
    );
  }

  String _time(DateTime tanggal) =>
      '${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}';
}

String _initialsOf(String name) {
  final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'NN';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}
