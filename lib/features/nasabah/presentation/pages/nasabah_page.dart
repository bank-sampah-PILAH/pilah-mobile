import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_paged_list_view.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_surface.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_table.dart';

class NasabahPage extends StatelessWidget {
  const NasabahPage({super.key});

  static const route = '/nasabah';

  @override
  Widget build(BuildContext context) {
    return const _NasabahPageBody();
  }
}

class _NasabahPageBody extends StatefulWidget {
  const _NasabahPageBody();

  @override
  State<_NasabahPageBody> createState() => _NasabahPageBodyState();
}

class _NasabahPageBodyState extends State<_NasabahPageBody> {
  void _tambahNasabah() => showNasabahSurface<void>(
        context,
        builder: (context) => const TambahNasabahBottomSheet(),
      );

  @override
  void initState() {
    super.initState();
    // Load with the authenticated session when the tab is first opened.
    context.read<NasabahCubit>().loadNasabah(pageSize: kIsWeb ? 10 : null);
  }

  @override
  Widget build(BuildContext context) {
    if (context.layoutBreakpoint != LayoutBreakpoint.compact) {
      return Scaffold(
        backgroundColor:
            WebContentSurface.pageColor(context, phone: Colors.white),
        body: const SafeArea(child: NasabahTable()),
      );
    }
    return Scaffold(
      backgroundColor:
          WebContentSurface.pageColor(context, phone: Colors.white),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              heroTag: 'nasabah_page_fab',
              onPressed: _tambahNasabah,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Daftar Nasabah',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.headline1.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  BlocBuilder<NasabahCubit, NasabahState>(
                    builder: (context, state) {
                      final activeCount =
                          context.read<NasabahCubit>().activeCount;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$activeCount aktif',
                          style: AppTextStyle.small.copyWith(
                            color: AppColors.greenDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  if (kIsWeb)
                    IconButton(
                      tooltip: 'Tambah Nasabah',
                      onPressed: _tambahNasabah,
                      icon: const Icon(Icons.add, color: AppColors.greenDark),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              CustomSearchField(
                hintText: 'Cari nama nasabah...',
                onChanged: (value) {
                  context.read<NasabahCubit>().searchNasabah(value);
                },
              ),
              const SizedBox(height: 16),

              // Filter Chips
              BlocBuilder<NasabahCubit, NasabahState>(
                buildWhen: (previous, current) {
                  if (previous is NasabahLoaded && current is NasabahLoaded) {
                    return previous.isActiveTab != current.isActiveTab;
                  }
                  return true;
                },
                builder: (context, state) {
                  final isActiveTab = state is NasabahLoaded
                      ? state.isActiveTab
                      : state is NasabahLoading
                          ? state.isActiveTab
                          : context.read<NasabahCubit>().isActiveTab;
                  final chips = NasabahFilterChips(
                    activeTab: isActiveTab,
                    onTabChanged: (value) {
                      context.read<NasabahCubit>().setActiveTab(value);
                    },
                  );
                  return kIsWeb
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: chips,
                        )
                      : chips;
                },
              ),
              const SizedBox(height: 16),

              // List View
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: AppRefreshIndicator(
                        onRefresh: () => context
                            .read<NasabahCubit>()
                            .loadNasabah(silent: true),
                        child: BlocBuilder<NasabahCubit, NasabahState>(
                          builder: (context, state) {
                            if (state is NasabahLoading ||
                                state is NasabahInitial) {
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

                            if (state is NasabahLoaded) {
                              final customers = state.nasabahList;

                              final Widget content;
                              if (customers.isEmpty) {
                                if (state.searchQuery.isNotEmpty) {
                                  content = const EmptyView(
                                    title: 'Nasabah Tidak Ditemukan',
                                    subtitle: 'Coba kata kunci yang berbeda',
                                    icon: Icons.search_off,
                                  );
                                } else {
                                  content = EmptyView(
                                    title: state.isMenungguTab
                                        ? 'Tidak Ada Pengajuan'
                                        : state.isActiveTab!
                                            ? 'Belum Ada Nasabah'
                                            : 'Tidak Ada Nasabah Nonaktif',
                                    subtitle: state.isMenungguTab
                                        ? 'Belum ada pengajuan keanggotaan yang menunggu persetujuan.'
                                        : state.isActiveTab!
                                            ? 'Tekan tombol + untuk menambah nasabah pertama.'
                                            : 'Semua nasabah masih berstatus aktif.',
                                    icon: state.isMenungguTab
                                        ? Icons.hourglass_empty
                                        : state.isActiveTab!
                                            ? Icons.people_outline
                                            : Icons.person_off_outlined,
                                  );
                                }
                              } else {
                                content = NasabahPagedListView(
                                  items: customers,
                                  hasMore: !kIsWeb && state.hasMore,
                                  isLoadingMore: !kIsWeb && state.isLoadingMore,
                                  onLoadMore: () => context
                                      .read<NasabahCubit>()
                                      .loadMoreNasabah(),
                                  nasabahCubit: context.read<NasabahCubit>(),
                                );
                              }

                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  content,
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: SizedBox(
                                      height: 2,
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        child: state.isReloading
                                            ? LinearProgressIndicator(
                                                key:
                                                    const ValueKey('reloading'),
                                                minHeight: 2,
                                                color: AppColors.greenDark,
                                                backgroundColor:
                                                    AppColors.greenLight,
                                              )
                                            : const SizedBox.shrink(
                                                key: ValueKey('idle'),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Rendered as a scrollable EmptyView rather than a blank
                            // box so a failed load can be retried by pulling down.
                            if (state is NasabahError) {
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
                    if (kIsWeb)
                      BlocBuilder<NasabahCubit, NasabahState>(
                        builder: (context, state) => state is NasabahLoaded
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: WebPaginationBar(
                                  currentPage: state.currentPage,
                                  totalItems: state.totalCount,
                                  pageSize: state.pageSize,
                                  itemLabel: 'nasabah',
                                  onPageChanged:
                                      context.read<NasabahCubit>().loadPage,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
