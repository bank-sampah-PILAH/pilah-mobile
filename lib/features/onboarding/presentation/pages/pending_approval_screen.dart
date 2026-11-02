import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  static const route = '/pending-approval';

  Widget _buildStep({
    required bool isCompleted,
    required bool isLast,
    required String title,
    required String subtitle,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.greenDark : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isCompleted
                      ? null
                      : Border.all(color: AppColors.grey200, width: 3),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.grey200,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? AppColors.greenDark
                        // Only reachable for an incomplete step that is not last;
                        // the screen's fixed steps never include one.
                        : AppColors.border, // coverage:ignore-line
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.md,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: AppFontSize.sm,
                      color: AppColors.grey100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authenticationProvider, (previous, state) {
      if (state is Unauthenticated) context.go('/login');
    });
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 70, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                color: AppColors.greenDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pendaftaran Terkirim!',
                    style: TextStyle(
                      fontSize: AppFontSize.display,
                      fontWeight: AppFontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menunggu tinjauan dari Admin.',
                    style: TextStyle(
                      fontSize: AppFontSize.md,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 2. Central Icon and Title
            const Icon(
              Icons.access_time_filled,
              size: 64,
              color: AppColors.grey200,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sedang Diproses',
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: AppFontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin sedang meninjau data institusi Anda.',
              style: TextStyle(
                fontSize: AppFontSize.md,
                color: AppColors.grey100,
              ),
            ),

            const SizedBox(height: 32),

            // 3. Progress Tracker Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStep(
                      isCompleted: true,
                      isLast: false,
                      title: 'Profil diri dilengkapi',
                      subtitle: 'Data personal PIC sudah tersimpan',
                    ),
                    _buildStep(
                      isCompleted: true,
                      isLast: false,
                      title: 'Data institusi dikirim',
                      subtitle: 'Formulir registrasi bank sampah diterima',
                    ),
                    _buildStep(
                      isCompleted: false,
                      isLast: true,
                      title: 'Ditinjau Admin (Tahap Saat Ini)',
                      subtitle:
                          'Proses verifikasi membutuhkan waktu estimasi 5 hari kerja',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Info Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.grey100, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Silakan periksa halaman ini secara berkala. Status pendaftaran Anda akan otomatis diperbarui di layar ini.',
                        style: TextStyle(
                          fontSize: AppFontSize.sm,
                          color: AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 5. Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AppButton(
                label: 'Kembali ke Halaman Login',
                variant: AppButtonVariant.neutral,
                onPressed: () {
                  // Real logout: revoke + clear the token, then the listener
                  // above routes back to login on Unauthenticated.
                  ref.read(authenticationProvider.notifier).logout();
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
