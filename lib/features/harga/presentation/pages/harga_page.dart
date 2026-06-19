import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

class HargaPage extends StatefulWidget {
  const HargaPage({super.key});

  static const route = '/harga';

  @override
  State<HargaPage> createState() => _HargaPageState();
}

class _HargaPageState extends State<HargaPage> {
  bool isActiveTab = true;

  @override
  Widget build(BuildContext context) {
    const Color emeraldPrimary = Color(0xFF006D44);
    
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true, 
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TambahJenisSampahBottomSheet(),
          );
        },
        backgroundColor: AppColors.greenDark,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Text(
                'Jenis Sampah & Harga',
                style: AppTextStyle.headline1.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari jenis sampah...',
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
              
              // Filter Chips
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isActiveTab = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActiveTab ? emeraldPrimary : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Aktif',
                        style: AppTextStyle.small.copyWith(
                          color: isActiveTab ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isActiveTab = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: !isActiveTab ? emeraldPrimary : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Tidak Aktif',
                        style: AppTextStyle.small.copyWith(
                          color: !isActiveTab ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // List View / Empty State
              Expanded(
                child: isActiveTab
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
                      children: _buildActivePrices(),
                    )
                  : _buildEmptyState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActivePrices() {
    return [
      _buildHargaCard(
        icon: Icons.recycling,
        title: 'Plastik PET',
        subtitle: 'Botol bening, kemasan',
        badgeText: 'Anorganik',
        price: 'Rp 3.500',
      ),
      const SizedBox(height: 12),
      _buildHargaCard(
        icon: Icons.description,
        title: 'Kertas HVS',
        subtitle: 'Kertas dokumen, buku',
        badgeText: 'Anorganik',
        price: 'Rp 1.200',
      ),
      const SizedBox(height: 12),
      _buildHargaCard(
        icon: Icons.inventory_2,
        title: 'Kardus',
        subtitle: 'Karton tebal, box',
        badgeText: 'Anorganik',
        price: 'Rp 1.500',
      ),
      const SizedBox(height: 12),
      _buildHargaCard(
        icon: Icons.settings,
        title: 'Logam Besi',
        subtitle: 'Besi tua, kaleng',
        badgeText: 'Anorganik',
        price: 'Rp 4.000',
      ),
      const SizedBox(height: 12),
      _buildHargaCard(
        icon: Icons.local_drink, // Placeholder for Aluminium can
        title: 'Aluminium',
        subtitle: 'Kaleng minuman, foil',
        badgeText: 'Anorganik',
        price: 'Rp 8.000',
      ),
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100], // surface-container-low or f3f4f6
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Jenis Nonaktif',
            style: AppTextStyle.headline1.copyWith(
              color: Colors.grey[600], // on-surface-variant
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua jenis sampah masih aktif.',
            style: AppTextStyle.small.copyWith(
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHargaCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required String price,
  }) {
    return Container(
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
          // Leading icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          // Middle content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.title1.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyle.extraSmall.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Trailing content
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'HARGA BELI',
                style: AppTextStyle.extraSmall.copyWith(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: AppTextStyle.title1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    ' / kg',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
