import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/core/utils/formatter/wa_template_renderer.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/riwayat_harga_page.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/design/widgets/app_tappable_card.dart';

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
  @override
  void initState() {
    super.initState();
    context.read<HargaCubit>().loadHarga();
  }

  @override
  Widget build(BuildContext context) {
    final hargaCubit = context.read<HargaCubit>();

    return Scaffold(
      backgroundColor:
          WebContentSurface.pageColor(context, phone: Colors.white),
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
                  final isActiveTab =
                      state is HargaLoaded ? state.isActiveTab : true;
                  return Row(
                    children: [
                      AppChip(
                        label: 'Aktif',
                        selected: isActiveTab,
                        onTap: () =>
                            context.read<HargaCubit>().setActiveTab(true),
                      ),
                      const SizedBox(width: 8),
                      AppChip(
                        label: 'Tidak Aktif',
                        selected: !isActiveTab,
                        onTap: () =>
                            context.read<HargaCubit>().setActiveTab(false),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // List View
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () =>
                      context.read<HargaCubit>().loadHarga(silent: true),
                  child: BlocBuilder<HargaCubit, HargaState>(
                    builder: (context, state) {
                      if (state is HargaLoading || state is HargaInitial) {
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: 5,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              const SkeletonListItem(),
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
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
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
    final terjadwal = item.hargaTerjadwal;

    return AppTappableCard(
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
      child: Row(
        children: [
          // Leading icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppRadius.md),
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
                if (terjadwal != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${CurrencyFormatter.formatRupiah(terjadwal.harga)} mulai '
                    '${formatTanggalId(terjadwal.berlakuMulai.toLocal())}',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.avatarYellowText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                // Its own tap target: tapping elsewhere on the card still
                // opens the edit sheet.
                TextButton(
                  onPressed: () =>
                      context.push(RiwayatHargaPage.route, extra: item),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.greenDark,
                  ),
                  child: Text(
                    'Riwayat harga',
                    style: AppTextStyle.extraSmall.copyWith(
                      color: AppColors.greenDark,
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
