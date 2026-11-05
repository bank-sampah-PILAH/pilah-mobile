import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/search_analytics.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_search_provider.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/states/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_filter_chips.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_order_controls.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_paged_list_view.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_search_field.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/tambah_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/web_pagination_bar.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_table.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

class NasabahPage extends StatelessWidget {
  const NasabahPage({super.key, this.isWeb = kIsWeb});

  static const route = '/nasabah';
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return _NasabahPageBody(isWeb: isWeb);
  }
}

class _NasabahPageBody extends ConsumerStatefulWidget {
  const _NasabahPageBody({required this.isWeb});
  final bool isWeb;

  @override
  ConsumerState<_NasabahPageBody> createState() => _NasabahPageBodyState();
}

class _NasabahPageBodyState extends ConsumerState<_NasabahPageBody> {
  void _tambahNasabah() => showAdaptiveSurface<void>(
        context,
        builder: (context) => const TambahNasabahBottomSheet(),
      );

  late final SearchAnalytics _search;

  /// The list's state changed: tell the search session what is being searched
  /// and what it found. Loading the same search again (another order, a further
  /// page) is not a new attempt, and the session ignores it.
  void _reportSearch(NasabahState? _, NasabahState now) {
    if (now is! NasabahLoaded) return;
    _search.queryChanged(now.searchQuery);
    if (now.isReloading || now.searchQuery.length < SearchAnalytics.minLength) {
      return;
    }
    _search.resultsSettled(
      query: now.searchQuery,
      count: now.totalCount,
      filter: switch (now.isActiveTab) {
        true => 'aktif',
        false => 'tidak_aktif',
        null => 'menunggu',
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _search = ref.read(nasabahSearchProvider);
    // Load with the authenticated session when the tab is first opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(nasabahProvider.notifier).loadNasabah(
              pageSize: widget.isWeb ? 10 : null,
            );
      }
    });
  }

  @override
  void dispose() {
    _search.closed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nasabahProvider);
    final notifier = ref.read(nasabahProvider.notifier);
    ref.listen<NasabahState>(nasabahProvider, _reportSearch);
    if (context.layoutBreakpoint != LayoutBreakpoint.compact) {
      return Scaffold(
        backgroundColor:
            WebContentSurface.pageColor(context, phone: Colors.white),
        body: SafeArea(child: NasabahTable(isWeb: widget.isWeb)),
      );
    }
    return Scaffold(
      backgroundColor:
          WebContentSurface.pageColor(context, phone: Colors.white),
      floatingActionButton: widget.isWeb
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
                        color: AppColors.black,
                        fontWeight: AppFontWeight.bold,
                        fontSize: AppFontSize.display,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${notifier.activeCount} aktif',
                      style: AppTextStyle.small.copyWith(
                        color: AppColors.greenDark,
                        fontWeight: AppFontWeight.semibold,
                      ),
                    ),
                  ),
                  if (widget.isWeb)
                    IconButton(
                      tooltip: 'Tambah Nasabah',
                      onPressed: _tambahNasabah,
                      icon: const Icon(Icons.add, color: AppColors.greenDark),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              const NasabahSearchField(),
              const SizedBox(height: 16),

              // Filter Chips
              Builder(builder: (context) {
                final isActiveTab = state is NasabahLoaded
                    ? state.isActiveTab
                    : state is NasabahLoading
                        ? state.isActiveTab
                        : notifier.isActiveTab;
                final chips = NasabahFilterChips(
                  activeTab: isActiveTab,
                  onTabChanged: notifier.setActiveTab,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chips,
                );
              }),
              const NasabahOrderControls(),
              const SizedBox(height: 16),

              // List View
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: AppRefreshIndicator(
                        onRefresh: () => notifier.loadNasabah(silent: true),
                        child: _buildStateContent(state, notifier),
                      ),
                    ),
                    if (widget.isWeb && state is NasabahLoaded)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: WebPaginationBar(
                          currentPage: state.currentPage,
                          totalItems: state.totalCount,
                          pageSize: state.pageSize,
                          itemLabel: 'nasabah',
                          onPageChanged: notifier.loadPage,
                        ),
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

  Widget _buildStateContent(
    NasabahState state,
    NasabahNotifier notifier,
  ) {
    if (state is NasabahLoading || state is NasabahInitial) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => const SkeletonListItem(),
      );
    }
    if (state is NasabahLoaded) return _buildLoadedState(state, notifier);
    if (state is NasabahError) {
      return EmptyView(
        title: 'Gagal Memuat Data',
        subtitle: state.message,
        icon: Icons.error_outline,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildLoadedState(NasabahLoaded state, NasabahNotifier notifier) {
    final customers = state.nasabahList;
    final content = customers.isEmpty
        ? _buildEmptyState(state)
        : NasabahPagedListView(
            items: customers,
            hasMore: !widget.isWeb && state.hasMore,
            isLoadingMore: !widget.isWeb && state.isLoadingMore,
            onLoadMore: notifier.loadMoreNasabah,
          );

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
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: state.isReloading
                  ? const LinearProgressIndicator(
                      key: ValueKey('reloading'),
                      minHeight: 2,
                      color: AppColors.greenDark,
                      backgroundColor: AppColors.greenLight,
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(NasabahLoaded state) {
    if (state.searchQuery.isNotEmpty) {
      return const EmptyView(
        title: 'Nasabah Tidak Ditemukan',
        subtitle: 'Coba kata kunci yang berbeda',
        icon: Icons.search_off,
      );
    }
    if (state.isMenungguTab) {
      return const EmptyView(
        title: 'Tidak Ada Pengajuan',
        subtitle: 'Belum ada pengajuan keanggotaan yang menunggu persetujuan.',
        icon: Icons.hourglass_empty,
      );
    }
    if (state.isActiveTab!) {
      return const EmptyView(
        title: 'Belum Ada Nasabah',
        subtitle: 'Tekan tombol + untuk menambah nasabah pertama.',
        icon: Icons.people_outline,
      );
    }
    return const EmptyView(
      title: 'Tidak Ada Nasabah Nonaktif',
      subtitle: 'Semua nasabah masih berstatus aktif.',
      icon: Icons.person_off_outlined,
    );
  }
}
