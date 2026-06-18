import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';

class NasabahListView extends StatelessWidget {
  final bool isActiveTab;

  const NasabahListView({
    super.key,
    required this.isActiveTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      children: isActiveTab ? _buildActiveCustomers() : _buildInactiveCustomers(),
    );
  }

  List<Widget> _buildActiveCustomers() {
    return const [
      NasabahListItem(
        isActive: true,
        initials: 'AR',
        avatarColor: AppColors.greenLight,
        textColor: AppColors.greenDark,
        name: 'Ahmad Ridwan',
        phone: '0812-3456-7890',
        balance: 'Rp 450.000',
      ),
      SizedBox(height: 12),
      NasabahListItem(
        isActive: true,
        initials: 'BS',
        avatarColor: AppColors.statPurpleLight,
        textColor: AppColors.statPurple,
        name: 'Budi Santoso',
        phone: '0857-1122-3344',
        balance: 'Rp 125.500',
      ),
      SizedBox(height: 12),
      NasabahListItem(
        isActive: true,
        initials: 'CW',
        avatarColor: AppColors.avatarYellow,
        textColor: AppColors.avatarYellowText,
        name: 'Citra Wijaya',
        phone: '0896-9988-7766',
        balance: 'Rp 890.000',
      ),
      SizedBox(height: 12),
      NasabahListItem(
        isActive: true,
        initials: 'EP',
        avatarColor: Color(0xFFE0F7FA), // cyanLight
        textColor: Color(0xFF00838F), // cyanDark
        name: 'Eko Prasetyo',
        phone: '0813-5678-9012',
        balance: 'Rp 215.000',
      ),
    ];
  }

  List<Widget> _buildInactiveCustomers() {
    return [
      NasabahListItem(
        isActive: false,
        initials: 'DP',
        avatarColor: const Color(0xFFDCE2F7), // surface-variant
        textColor: Colors.grey[500]!, // using grey for muted initials text
        name: 'Dewi Putri',
        phone: '0811-2223-4455',
        balance: 'Rp 35.000',
      ),
      const SizedBox(height: 12),
      NasabahListItem(
        isActive: false,
        initials: 'FH',
        avatarColor: const Color(0xFFDCE2F7), // surface-variant
        textColor: Colors.grey[500]!, // using grey for muted initials text
        name: 'Farida Hanum',
        phone: '0878-4321-0987',
        balance: 'Rp 75.000',
      ),
    ];
  }
}
