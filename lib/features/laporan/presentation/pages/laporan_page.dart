import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/laporan/presentation/widgets/detail_transaksi_bottom_sheet.dart';
import 'package:pilah_mobile/features/laporan/presentation/widgets/filter_tanggal_bottom_sheet.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  static const route = '/laporan';

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String activeFilter = 'Hari Ini';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Semua Transaksi',
                        style: AppTextStyle.headline1.copyWith(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama pelanggan...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row
                  Row(
                    children: [
                      _buildFilterChip('Hari Ini'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Minggu Ini'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bulan Ini'),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true, 
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const FilterTanggalBottomSheet(),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Scrollable List Section
            Expanded(
              child: _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final query = searchQuery.toLowerCase();
    
    // In a real app, you would also filter by activeFilter ('Hari Ini', 'Minggu Ini', 'Bulan Ini')
    // For our dummy data, we will filter the existing data structure by search query
    
    List<Map<String, dynamic>> filteredGroups = [];
    for (var group in _transactionsData) {
      final transactions = (group['transactions'] as List<Map<String, dynamic>>).where((t) {
        final name = (t['name'] as String).toLowerCase();
        return name.contains(query);
      }).toList();
      
      if (transactions.isNotEmpty) {
        filteredGroups.add({
          'header': group['header'],
          'transactions': transactions,
        });
      }
    }

    if (filteredGroups.isEmpty) {
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
              'Transaksi Tidak Ditemukan',
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci atau nama pelanggan lain',
              style: AppTextStyle.small.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 24),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        final header = group['header'] as String;
        final transactions = group['transactions'] as List<Map<String, dynamic>>;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(header),
            ...transactions.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildTransactionCard(
                initials: t['initials'],
                avatarColor: t['avatarColor'],
                textColor: t['textColor'],
                name: t['name'],
                subtitle: t['subtitle'],
                amount: t['amount'],
                isWaSuccess: t['isWaSuccess'],
                time: t['time'],
                balance: t['balance'],
                items: t['items'],
              ),
            )),
            if (index < filteredGroups.length - 1)
              const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _transactionsData => [
    {
      'header': 'HARI INI',
      'transactions': [
        {
          'initials': 'BS',
          'avatarColor': AppColors.greenLight,
          'textColor': AppColors.greenDark,
          'name': 'Budi Santoso',
          'subtitle': 'Plastik • 5.2 kg',
          'amount': '+Rp 15.600',
          'isWaSuccess': true,
          'time': '09:45',
          'balance': 'Rp 141.100',
          'items': [
            {'jenis': 'Plastik PET', 'berat': '5.2 kg', 'harga': 'Rp 3.000', 'subtotal': 'Rp 15.600'},
          ],
        },
        {
          'initials': 'WS',
          'avatarColor': AppColors.avatarYellow,
          'textColor': AppColors.avatarYellowText,
          'name': 'Warung Bu Siti',
          'subtitle': 'Logam • 2.1 kg',
          'amount': '+Rp 10.500',
          'isWaSuccess': false,
          'time': '08:30',
          'balance': 'Rp 45.500',
          'items': [
            {'jenis': 'Logam Besi', 'berat': '2.1 kg', 'harga': 'Rp 5.000', 'subtotal': 'Rp 10.500'},
          ],
        },
      ]
    },
    {
      'header': 'KEMARIN',
      'transactions': [
        {
          'initials': 'KD',
          'avatarColor': const Color(0xFFE8EAF6),
          'textColor': const Color(0xFF3F51B5),
          'name': 'Kantor Desa Mekar',
          'subtitle': 'Kertas • 12.0 kg',
          'amount': '+Rp 24.000',
          'isWaSuccess': true,
          'time': null,
          'balance': 'Rp 224.000',
          'items': [
            {'jenis': 'Kertas HVS', 'berat': '12.0 kg', 'harga': 'Rp 2.000', 'subtotal': 'Rp 24.000'},
          ],
        },
        {
          'initials': 'AY',
          'avatarColor': AppColors.greenLight,
          'textColor': AppColors.greenDark,
          'name': 'Ahmad Yani',
          'subtitle': 'Plastik • 3.5 kg',
          'amount': '+Rp 10.500',
          'isWaSuccess': true,
          'time': null,
          'balance': 'Rp 50.500',
          'items': [
            {'jenis': 'Plastik PET', 'berat': '3.5 kg', 'harga': 'Rp 3.000', 'subtotal': 'Rp 10.500'},
          ],
        },
      ]
    },
    {
      'header': '3 HARI LALU',
      'transactions': [
        {
          'initials': 'CW',
          'avatarColor': const Color(0xFFFCE4EC),
          'textColor': const Color(0xFFE91E63),
          'name': 'Citra Wijaya',
          'subtitle': 'Aluminium • 1.8 kg',
          'amount': '+Rp 14.400',
          'isWaSuccess': false,
          'time': null,
          'balance': 'Rp 104.400',
          'items': [
            {'jenis': 'Aluminium', 'berat': '1.8 kg', 'harga': 'Rp 8.000', 'subtotal': 'Rp 14.400'},
          ],
        },
      ]
    },
  ];

  Widget _buildFilterChip(String label) {
    final bool isSelected = activeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          activeFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.greenDark : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTransactionCard({
    required String initials,
    required Color avatarColor,
    required Color textColor,
    required String name,
    required String subtitle,
    required String amount,
    required bool isWaSuccess,
    required String balance,
    required List<Map<String, dynamic>> items,
    String? time,
  }) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true, 
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DetailTransaksiBottomSheet(
            transactionData: {
              'initials': initials,
              'avatarColor': avatarColor,
              'textColor': textColor,
              'name': name,
              'time': time ?? 'Hari ini',
              'amount': amount,
              'balance': balance,
              'waStatus': isWaSuccess ? 'sent' : 'failed',
              'items': items,
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTextStyle.title1.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyle.small.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyle.title1.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isWaSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWaSuccess ? Icons.check : Icons.close,
                          color: isWaSuccess ? Colors.green[600] : Colors.red[600],
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'WA',
                          style: TextStyle(
                            color: isWaSuccess ? Colors.green[600] : Colors.red[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: AppTextStyle.extraSmall.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
