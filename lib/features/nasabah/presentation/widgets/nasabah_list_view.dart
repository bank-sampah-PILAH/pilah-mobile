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
          idNasabah: customer['idNasabah'],
          jenisKelamin: customer['jenisKelamin'],
          tanggalLahir: customer['tanggalLahir'],
          address: customer['address'],
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
      'phone': '+6281234567890',
      'balance': 'Rp 450.000',
      'idNasabah': 'NAS-0001',
      'jenisKelamin': 'Laki-laki',
      'tanggalLahir': '15/04/1988',
      'address': 'Jl. Mawar No. 12, RT 02/03, Kukusan, Depok',
    },
    {
      'initials': 'BS',
      'avatarColor': AppColors.statPurpleLight,
      'textColor': AppColors.statPurple,
      'name': 'Budi Santoso',
      'phone': '+6285711223344',
      'balance': 'Rp 125.500',
      'idNasabah': 'NAS-0002',
      'jenisKelamin': 'Laki-laki',
      'tanggalLahir': '21/08/1990',
      'address': 'Jl. Melati Blok C No. 4, Pancoran Mas, Depok',
    },
    {
      'initials': 'SR',
      'avatarColor': AppColors.avatarYellow,
      'textColor': AppColors.avatarYellowText,
      'name': 'Siti Rahayu',
      'phone': '+6289699887766',
      'balance': 'Rp 890.000',
      'idNasabah': 'NAS-0003',
      'jenisKelamin': 'Perempuan',
      'tanggalLahir': '12/05/1985',
      'address': 'Perumahan Indah Asri Blok B, Margonda, Depok',
    },
    {
      'initials': 'EP',
      'avatarColor': const Color(0xFFE0F7FA),
      'textColor': const Color(0xFF00838F),
      'name': 'Eko Prasetyo',
      'phone': '+6281356789012',
      'balance': 'Rp 215.000',
      'idNasabah': 'NAS-0004',
      'jenisKelamin': 'Laki-laki',
      'tanggalLahir': '30/09/1985',
      'address': 'Komp. Polri, Ragunan, Pasar Minggu, Jakarta Selatan',
    },
  ];

  List<Map<String, dynamic>> get _inactiveCustomers => [
    {
      'initials': 'DP',
      'avatarColor': const Color(0xFFDCE2F7),
      'textColor': Colors.grey[500]!,
      'name': 'Dewi Putri',
      'phone': '+6281122234455',
      'balance': 'Rp 35.000',
      'idNasabah': 'NAS-0005',
      'jenisKelamin': 'Perempuan',
      'tanggalLahir': '18/02/1995',
      'address': 'Jl. Pahlawan No. 45, Bekasi Timur',
    },
    {
      'initials': 'FH',
      'avatarColor': const Color(0xFFDCE2F7),
      'textColor': Colors.grey[500]!,
      'name': 'Farida Hanum',
      'phone': '+6287843210987',
      'balance': 'Rp 75.000',
      'idNasabah': 'NAS-0006',
      'jenisKelamin': 'Perempuan',
      'tanggalLahir': '23/08/1992',
      'address': 'Jl. Merdeka Raya Kav. 8, Sukmajaya, Depok',
    },
  ];
}
