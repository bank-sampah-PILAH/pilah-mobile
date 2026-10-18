import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_search_field.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(builder: (context, constraints) {
                        final title = Text('Riwayat Aktivitas',
                            style: AppTextStyle.headline1);
                        final search = CustomSearchField(
                          hintText: 'Cari nama pelanggan...',
                          controller: _searchController,
                          onChanged:
                              context.read<RiwayatAktivitasCubit>().search,
                        );
                        if (LayoutBreakpoint.fromWidth(constraints.maxWidth) ==
                            LayoutBreakpoint.expanded) {
                          return Row(children: [
                            Expanded(child: title),
                            const SizedBox(width: 24),
                            SizedBox(width: 360, child: search),
                          ]);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [title, const SizedBox(height: 16), search],
                        );
                      }),
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
