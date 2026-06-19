import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

class PilihNasabahBottomSheet extends StatefulWidget {
  const PilihNasabahBottomSheet({super.key});

  @override
  State<PilihNasabahBottomSheet> createState() => _PilihNasabahBottomSheetState();
}

class _PilihNasabahBottomSheetState extends State<PilihNasabahBottomSheet> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Emerald Eco System Tokens
  static const Color emeraldPrimary = Color(0xFF006D44);
  static const Color mintTint = Color(0xFFF0FDF4);

  // Mock Active Customers
  final List<Map<String, dynamic>> _mockCustomers = [
    {
      'id': 'NAS-0891',
      'name': 'Ahmad Ridwan',
      'phone': '0812-3456-7890',
      'balance': 'Rp 450.000',
      'initials': 'AR',
      'avatarColor': const Color(0xFFD1FAE5), // mint tint
      'textColor': const Color(0xFF006D44), // emerald primary
    },
    {
      'id': 'NAS-0892',
      'name': 'Budi Santoso',
      'phone': '0857-1122-3344',
      'balance': 'Rp 125.500',
      'initials': 'BS',
      'avatarColor': const Color(0xFFE0E7FF),
      'textColor': const Color(0xFF4338CA),
    },
    {
      'id': 'NAS-0893',
      'name': 'Citra Wijaya',
      'phone': '0896-9988-7766',
      'balance': 'Rp 890.000',
      'initials': 'CW',
      'avatarColor': const Color(0xFFFEF3C7),
      'textColor': const Color(0xFFB45309),
    },
    {
      'id': 'NAS-0895',
      'name': 'Eko Prasetyo',
      'phone': '0813-5678-9012',
      'balance': 'Rp 215.000',
      'initials': 'EP',
      'avatarColor': const Color(0xFFCFFAFE),
      'textColor': const Color(0xFF0E7490),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter customers
    final filteredCustomers = _mockCustomers.where((customer) {
      final query = searchQuery.toLowerCase();
      final nameMatches = (customer['name'] as String).toLowerCase().contains(query);
      return nameMatches;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Text(
              'Pilih Nasabah',
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama...',
                hintStyle: AppTextStyle.small.copyWith(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyle.small.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  return InkWell(
                    onTap: () {
                      context.pop(customer);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: customer['avatarColor'],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              customer['initials'],
                              style: AppTextStyle.title1.copyWith(
                                color: customer['textColor'],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer['name'],
                                  style: AppTextStyle.title1.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${customer['id']} · ${customer['phone']}',
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
                                'Saldo',
                                style: AppTextStyle.extraSmall.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                customer['balance'],
                                style: AppTextStyle.title1.copyWith(
                                  color: emeraldPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
