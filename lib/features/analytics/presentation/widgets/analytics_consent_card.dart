import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';

/// Lets a pengurus see, and change, whether the steps they take are noted.
/// Shown only where it applies: to a pengurus, on a platform that can send.
class AnalyticsConsentCard extends ConsumerWidget {
  const AnalyticsConsentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(analyticsToggleVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final allowed =
        ref.watch(analyticsConsentProvider).value == ConsentChoice.granted;
    final consent = ref.read(analyticsConsentProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analitik penggunaan',
                  style: AppTextStyle.title1.copyWith(color: AppColors.black),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Izinkan PILAH mencatat langkah pemakaian aplikasi agar kami '
                  'bisa meningkatkannya. Data dikirim ke PostHog, penyedia '
                  'analitik di luar negeri, bersama jenis perangkat, peramban, '
                  'dan perkiraan lokasi dari alamat IP. Isi layar dan alamat '
                  'halaman tidak dicatat.',
                  style: AppTextStyle.small.copyWith(color: AppColors.grey100),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Switch(
            value: allowed,
            onChanged: (agreed) => agreed ? consent.grant() : consent.revoke(),
          ),
        ],
      ),
    );
  }
}
