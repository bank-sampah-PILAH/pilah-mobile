import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  static const route = '/superadmin-dashboard';

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  String _activeTab = 'Menunggu';

  Widget _buildTab(String label) {
    final isActive = _activeTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.greenDark : Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.greenDark,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SuperAdmin PILAH',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manajemen Bank Sampah',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.go('/login'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Tabs Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTab('Menunggu'),
                      _buildTab('Disetujui'),
                      _buildTab('Ditolak'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content Area
          Expanded(
            child: _buildContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_activeTab == 'Menunggu') {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PendingBankCard(
            bankName: 'Bank Sampah Mekar Jaya',
            regId: 'REG-001',
            picName: 'Siti Rahayu',
            address: 'Jl. Cempaka No.12, Kukusan, Beji, Depok',
            submittedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          const SizedBox(height: 16),
          PendingBankCard(
            bankName: 'Bank Sampah Bersih Bersama',
            regId: 'REG-002',
            picName: 'Hendra Gunawan',
            address: 'Jl. Anggrek Blok B3, Sawangan, Depok',
            submittedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
      );
    } else if (_activeTab == 'Disetujui') {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ApprovedBankCard(
            bankName: 'Bank Sampah BTH',
            regId: 'REG-000',
            picName: 'Ahmad Fadil',
            date: 'Disetujui: 10 Jan 2026',
          ),
          const SizedBox(height: 24),
          Text(
            'BS yang disetujui akan muncul di sini secara otomatis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.cancel_outlined,
                color: Colors.red.shade600,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Penolakan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pendaftaran yang ditolak akan tercatat di sini sebagai arsip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }
  }
}

class PendingBankCard extends StatelessWidget {
  final String bankName;
  final String regId;
  final String picName;
  final String address;
  final DateTime submittedAt;

  const PendingBankCard({
    super.key,
    required this.bankName,
    required this.regId,
    required this.picName,
    required this.address,
    required this.submittedAt,
  });

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return 'Diajukan: ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _calculateWaitingDays(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final submissionDate = DateTime(date.year, date.month, date.day);
    return today.difference(submissionDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B), // Orange-yellow accent
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            bankName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      regId,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Info Rows
                    _buildInfoRow(Icons.person_outline, '$picName (Ketua)'),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.location_on_outlined, address),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.calendar_today_outlined, _formatDate(submittedAt)),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.access_time_outlined, 'Menunggu: ${_calculateWaitingDays(submittedAt)} hari', isBold: true),
                    const SizedBox(height: 16),
                    
                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.image_outlined, size: 14, color: AppColors.greenDark),
                            label: const Text(
                              'Lihat Bukti',
                              style: TextStyle(fontSize: 12, color: AppColors.greenDark, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenLight,
                              foregroundColor: AppColors.greenDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.check, size: 14, color: Colors.white),
                            label: const Text(
                              'Setujui',
                              style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.close, size: 14, color: Colors.red),
                            label: const Text(
                              'Tolak',
                              style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isBold ? Colors.black87 : Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class ApprovedBankCard extends StatelessWidget {
  final String bankName;
  final String regId;
  final String picName;
  final String date;

  const ApprovedBankCard({
    super.key,
    required this.bankName,
    required this.regId,
    required this.picName,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent (Green)
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.greenDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            bankName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_box, color: AppColors.greenDark, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'AKTIF',
                                style: TextStyle(
                                  color: AppColors.greenDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      regId,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Info Rows (Only 2)
                    _buildInfoRow(Icons.person_outline, '$picName (Ketua)'),
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.calendar_today_outlined, date),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
