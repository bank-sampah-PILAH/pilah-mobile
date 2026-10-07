import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';

class RecentActivitySection extends StatelessWidget {
  final DateTime Function() now;

  const RecentActivitySection({super.key, this.now = DateTime.now});

  String _dayLabel(DateTime? tanggal) {
    if (tanggal == null) return 'Lainnya';
    final today = now();
    final diff = DateUtils.dateOnly(today)
        .difference(DateUtils.dateOnly(tanggal))
        .inDays;
    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '$diff hari lalu';
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
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.greenDark),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<RecentActivityCubit, RecentActivityState>(
          builder: (context, state) {
            if (state is RecentActivityLoading ||
                state is RecentActivityInitial) {
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
            if (state is RecentActivityError) {
              return _ActivityError(
                message: state.message,
                onRetry: () => context.read<RecentActivityCubit>().load(),
              );
            }

            // The cubit has already merged setoran+pencairan, sorted them, and
            // capped the total at RecentActivityCubit.limit.
            final items =
                state is RecentActivityLoaded ? state.items : const [];

            if (items.isEmpty) {
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
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  ActivityItem(
                    avatarText: items[i].avatarText,
                    avatarColor: items[i].avatarColor,
                    avatarTextColor: items[i].avatarTextColor,
                    title: items[i].title,
                    subtitleLines: items[i].subtitleLines,
                    amount: items[i].amount,
                    amountColor: items[i].amountColor,
                    trailingCaptions: items[i].trailingCaptions.isNotEmpty
                        ? items[i].trailingCaptions
                        : [_dayLabel(items[i].tanggal)],
                    badge: items[i].badge,
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
