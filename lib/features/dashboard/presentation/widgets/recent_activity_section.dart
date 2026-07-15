import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/activity_item.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';

class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  String _friendlyHeader(String header) {
    switch (header) {
      case 'HARI INI':
        return 'Hari ini';
      case 'KEMARIN':
        return 'Kemarin';
      default:
        final lower = header.toLowerCase();
        return lower.isEmpty ? lower : '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terbaru',
              style: AppTextStyle.title1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/laporan'),
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: AppTextStyle.small.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16, color: AppColors.greenDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<TransaksiCubit, TransaksiState>(
          builder: (context, state) {
            if (state is TransaksiLoading || state is TransaksiInitial) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            // A failed fetch must not read as "no transactions yet" — the two
            // look identical to the user but mean opposite things, and the
            // empty wording sends them looking for a data problem that isn't
            // there. Surface the failure and let them retry.
            if (state is TransaksiError) {
              return _ActivityError(
                message: state.message,
                onRetry: () => context.read<TransaksiCubit>().loadTransaksi(),
              );
            }

            // Flatten the groups and take the most recent few transactions,
            // keeping the day label from each group.
            final entries = <({TransaksiEntity trx, String header})>[];
            if (state is TransaksiLoaded) {
              for (final group in state.transaksiList) {
                for (final trx in group.transactions) {
                  entries.add((trx: trx, header: group.header));
                  if (entries.length >= 3) break;
                }
                if (entries.length >= 3) break;
              }
            }

            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada aktivitas transaksi.',
                    style: AppTextStyle.small.copyWith(color: Colors.grey[500]),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  ActivityItem(
                    avatarText: entries[i].trx.initials,
                    avatarColor: entries[i].trx.avatarColor,
                    avatarTextColor: entries[i].trx.textColor,
                    title: entries[i].trx.name,
                    subtitle: entries[i].trx.subtitle,
                    amount: entries[i].trx.amount,
                    time: entries[i].trx.time != null
                        ? '${_friendlyHeader(entries[i].header)}, ${entries[i].trx.time}'
                        : _friendlyHeader(entries[i].header),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Shown when the transaksi fetch fails, in place of the activity list.
class _ActivityError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ActivityError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: Colors.grey[400], size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.small.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Coba Lagi',
              style: AppTextStyle.small.copyWith(
                color: AppColors.greenDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
