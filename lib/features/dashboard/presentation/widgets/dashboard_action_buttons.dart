import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/transaksi/presentation/pages/transaksi_baru_page.dart';

class DashboardActionButtons extends StatelessWidget {
  const DashboardActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(TransaksiBaruPage.route);
            },
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            label: Text(
              'Setoran Baru',
              style: AppTextStyle.small.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // 1. Trigger the route change to the Nasabah tab
              context.go('/nasabah');
              
              // 2. Wait for the tab transition animation to complete before showing the modal
              Future.delayed(const Duration(milliseconds: 300), () {
                if (context.mounted) {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: true, 
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const TambahNasabahBottomSheet(),
                  );
                }
              });
            },
            icon: const Icon(Icons.person_add_outlined, color: AppColors.greenDark, size: 20),
            label: Text(
              'Tambah\nNasabah',
              style: AppTextStyle.small.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
