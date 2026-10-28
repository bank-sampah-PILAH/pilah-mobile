import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/bases/widgets/activity_item.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/recent_activity_state.dart';

class RecentActivitySection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recentActivityProvider);
    final items = state is RecentActivityLoaded ? state.items : const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Aktivitas Terbaru',
                style: AppTextStyle.title1.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
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
        if (state is RecentActivityLoading || state is RecentActivityInitial)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (state is RecentActivityError)
          _ActivityError(
            message: state.message,
            onRetry: () => ref.read(recentActivityProvider.notifier).load(),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Belum ada aktivitas transaksi.',
                style: AppTextStyle.small.copyWith(color: AppColors.grey100),
              ),
            ),
          )
        else
          Column(
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
            Icon(Icons.cloud_off, color: AppColors.grey200, size: 32),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.small.copyWith(color: AppColors.grey100),
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
