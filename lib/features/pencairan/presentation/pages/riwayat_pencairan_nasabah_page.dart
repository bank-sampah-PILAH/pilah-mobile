import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bankSampahNama.isEmpty
                            ? 'Bank Sampah'
                            : item.bankSampahNama,
                        style: AppTextStyle.title1.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tanggal == null ? '-' : formatTanggalId(tanggal),
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.grey100,
                        ),
                      ),
                      if (tanggal != null)
                        Text(
                          _time(tanggal),
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.grey100,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${formatRupiahId(item.nominal)}',
                      style: AppTextStyle.title1.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.diperbarui)
                      Text(
                        'Diperbarui',
                        style: AppTextStyle.small.copyWith(
                          color: AppColors.greenDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.metode.label, style: AppTextStyle.small),
            if (item.keterangan.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.keterangan, style: AppTextStyle.small),
            ],
          ],
        ),
      ),
    );
  }

  String _time(DateTime tanggal) =>
      '${tanggal.hour.toString().padLeft(2, '0')}:${tanggal.minute.toString().padLeft(2, '0')}';
}
