import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';

class HargaPage extends StatelessWidget {
  const HargaPage({super.key});

  static const route = '/harga';

  @override
  Widget build(BuildContext context) {
    return const _HargaPageBody();
  }
}

class _HargaPageBody extends StatefulWidget {
  const _HargaPageBody();

  @override
  State<_HargaPageBody> createState() => _HargaPageBodyState();
}

class _HargaPageBodyState extends State<_HargaPageBody> {
  static const Color emeraldPrimary = Color(0xFF006D44);

  @override
  void initState() {
    super.initState();
    context.read<HargaCubit>().loadHarga();
  }

  @override
  Widget build(BuildContext context) {
    final hargaCubit = context.read<HargaCubit>();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        heroTag: 'harga_page_fab',
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
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<HargaCubit>().loadHarga(silent: true),
                  color: AppColors.greenDark,
                  child: BlocBuilder<HargaCubit, HargaState>(
                    builder: (context, state) {
                      if (state is HargaLoading || state is HargaInitial) {
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: 5,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => const SkeletonListItem(),
                        );
                      }

                      if (state is HargaLoaded) {
                        final items = state.jenisSampahList;

                        if (items.isEmpty) {
                          if (state.searchQuery.isNotEmpty) {
                            return const EmptyView(
                              title: 'Jenis Sampah Tidak Ditemukan',
                              subtitle: 'Coba kata kunci yang berbeda',
                              icon: Icons.search_off,
                            );
                          }
                          return EmptyView(
                            title: state.isActiveTab
                                ? 'Belum Ada Jenis Sampah'
                                : 'Tidak Ada Jenis Nonaktif',
                            subtitle: state.isActiveTab
                                ? 'Tekan tombol + untuk menambah jenis sampah.'
                                : 'Semua jenis sampah masih aktif.',
                            icon: state.isActiveTab
                                ? Icons.category_outlined
                                : Icons.check_circle_outline,
                          );
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
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

                      // Rendered as a scrollable EmptyView rather than a blank
                      // box so a failed load can be retried by pulling down.
                      if (state is HargaError) {
                        return EmptyView(
                          title: 'Gagal Memuat Data',
                          subtitle: state.message,
                          icon: Icons.error_outline,
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHargaCard({
    required BuildContext context,
    required HargaCubit hargaCubit,
    required HargaEntity item,
  }) {
    final icon = item.icon;
    final title = item.name;
    final subtitle = item.subtitle;
    final badgeText = item.badgeText;
    final price = item.priceFormatted;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => TambahJenisSampahBottomSheet(
            hargaCubit: hargaCubit,
            initialData: item,
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
