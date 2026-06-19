import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';

class HargaPage extends StatelessWidget {
  const HargaPage({super.key});

  static const route = '/harga';

  @override
  Widget build(BuildContext context) {
    return const _HargaPageBody();
  }
}

class _HargaPageBody extends StatelessWidget {
  const _HargaPageBody();

  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  Widget build(BuildContext context) {
    final hargaCubit = context.read<HargaCubit>();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TambahJenisSampahBottomSheet(
              hargaCubit: hargaCubit,
            ),
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
              CustomSearchField(
                hintText: 'Cari jenis sampah...',
                onChanged: (value) {
                  context.read<HargaCubit>().searchHarga(value);
                },
              ),
              const SizedBox(height: 16),

              // Filter Chips
              BlocBuilder<HargaCubit, HargaState>(
                buildWhen: (previous, current) {
                  if (previous is HargaLoaded && current is HargaLoaded) {
                    return previous.isActiveTab != current.isActiveTab;
                  }
                  return true;
                },
                builder: (context, state) {
                  final isActiveTab = state is HargaLoaded ? state.isActiveTab : true;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.read<HargaCubit>().setActiveTab(true),
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
                        onTap: () => context.read<HargaCubit>().setActiveTab(false),
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
                  );
                },
              ),
              const SizedBox(height: 16),

              // List View
              Expanded(
                child: BlocBuilder<HargaCubit, HargaState>(
                  builder: (context, state) {
                    if (state is HargaLoading || state is HargaInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.greenDark,
                        ),
                      );
                    }

                    if (state is HargaLoaded) {
                      final items = state.jenisSampahList;

                      if (items.isEmpty) {
                        if (state.searchQuery.isNotEmpty) {
                          return _buildSearchEmptyState();
                        }
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildHargaCard(
                            context: context,
                            hargaCubit: hargaCubit,
                            item: item,
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState() {
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
            'Jenis Sampah Tidak Ditemukan',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
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
              color: Colors.grey[600],
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
    required BuildContext context,
    required HargaCubit hargaCubit,
    required Map<String, dynamic> item,
  }) {
    final icon = item['icon'] as IconData;
    final title = item['name'] as String;
    final subtitle = item['subtitle'] as String? ?? '';
    final badgeText = item['badgeText'] as String? ?? 'Anorganik';
    final price = item['priceFormatted'] as String? ?? 'Rp 0';

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TambahJenisSampahBottomSheet(
            hargaCubit: hargaCubit,
            initialData: {
              'id': item['id'],
              'title': title,
              'subtitle': subtitle,
              'badgeText': badgeText,
              'price': price,
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
                  CustomStatusBadge(
                    statusText: badgeText,
                    backgroundColor: Colors.blue[50],
                    textColor: Colors.blue[600],
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
      ),
    );
  }
}
