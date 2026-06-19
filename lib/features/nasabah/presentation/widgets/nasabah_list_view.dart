import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';

class NasabahListView extends StatelessWidget {
  final bool isActiveTab;
  final String searchQuery;

  const NasabahListView({
    super.key,
    required this.isActiveTab,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allCustomers = isActiveTab ? _activeCustomers : _inactiveCustomers;
    
    // Filter by search query
    final query = searchQuery.toLowerCase();
    final filteredCustomers = allCustomers.where((customer) {
      final name = (customer['name'] as String).toLowerCase();
      final phone = (customer['phone'] as String).toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Nasabah Tidak Ditemukan',
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci yang berbeda',
              style: AppTextStyle.small.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
      itemCount: filteredCustomers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = filteredCustomers[index];
        return NasabahListItem(
          isActive: isActiveTab,
          initials: customer['initials'],
          avatarColor: customer['avatarColor'],
          textColor: customer['textColor'],
          name: customer['name'],
          phone: customer['phone'],
          balance: customer['balance'],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _activeCustomers => [
    {
      'initials': 'AR',
      'avatarColor': AppColors.greenLight,
      'textColor': AppColors.greenDark,
      'name': 'Ahmad Ridwan',
      'phone': '0812-3456-7890',
      'balance': 'Rp 450.000',
    },
    {
      'initials': 'BS',
      'avatarColor': AppColors.statPurpleLight,
      'textColor': AppColors.statPurple,
      'name': 'Budi Santoso',
      'phone': '0857-1122-3344',
      'balance': 'Rp 125.500',
    },
    {
      'initials': 'CW',
      'avatarColor': AppColors.avatarYellow,
      'textColor': AppColors.avatarYellowText,
      'name': 'Citra Wijaya',
      'phone': '0896-9988-7766',
      'balance': 'Rp 890.000',
    },
    {
      'initials': 'EP',
      'avatarColor': const Color(0xFFE0F7FA),
      'textColor': const Color(0xFF00838F),
      'name': 'Eko Prasetyo',
      'phone': '0813-5678-9012',
      'balance': 'Rp 215.000',
    },
  ];

  List<Map<String, dynamic>> get _inactiveCustomers => [
    {
      'initials': 'DP',
      'avatarColor': const Color(0xFFDCE2F7),
      'textColor': Colors.grey[500]!,
      'name': 'Dewi Putri',
      'phone': '0811-2223-4455',
      'balance': 'Rp 35.000',
    },
    {
      'initials': 'FH',
      'avatarColor': const Color(0xFFDCE2F7),
      'textColor': Colors.grey[500]!,
      'name': 'Farida Hanum',
      'phone': '0878-4321-0987',
      'balance': 'Rp 75.000',
    },
  ];
}
