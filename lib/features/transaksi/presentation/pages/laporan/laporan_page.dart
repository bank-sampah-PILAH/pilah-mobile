import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/layout/content_bounds.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_list_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_summary_view.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/aktivitas_tipe_chips.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/time_filter_chips.dart';

/// One filtered report and activity feed for Pengurus on mobile and web.
class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  static const route = '/laporan';

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RiwayatAktivitasCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _webPadding(BuildContext context) =>
      context.layoutBreakpoint != LayoutBreakpoint.compact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          WebContentSurface.pageColor(context, phone: AppColors.surface),
      body: SafeArea(
        child: ContentBounds(
          child: NestedScrollView(
            // Let filters and totals scroll away on short screens or with a keyboard.
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: _webPadding(context)
                      ? const EdgeInsets.fromLTRB(
                          AppSpacing.webGutter,
                          AppSpacing.webTop,
                          AppSpacing.webGutter,
                          AppSpacing.lg,
                        )
                      : const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppPageHeader(
                        title: 'Riwayat Aktivitas',
                        search: CustomSearchField(
                          hintText: 'Cari nama pelanggan...',
                          controller: _searchController,
                          onChanged:
                              context.read<RiwayatAktivitasCubit>().search,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const AktivitasTipeChips(),
                      const SizedBox(height: 12),
                      const TimeFilterChips(),
                      const AktivitasSummaryView(),
                    ],
                  ),
                ),
              ),
            ],
            body: AppRefreshIndicator(
              onRefresh: () =>
                  context.read<RiwayatAktivitasCubit>().load(silent: true),
              child: const AktivitasListView(),
            ),
          ),
        ),
      ),
    );
  }
}
