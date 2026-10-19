import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_report_widgets.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_statistics_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_upcoming_schedule_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_web_kpi_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.isWeb});

  // `kIsWeb` is compile-time constant, so VM tests need this branch override.
  @visibleForTesting
  final bool? isWeb;

  static const route = AppLocations.dashboard;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load the current-month metrics from the backend when the dashboard opens.
    context.read<DashboardCubit>().loadStats();
    // Aktivitas Terbaru has its own cubit — see [RecentActivityCubit] for why
    // it is not the one Laporan drives — so nothing else loads it.
    context.read<RecentActivityCubit>().load();
  }

  /// Refetches everything the dashboard renders. The header's bank sampah name
  /// comes from the cached session rather than a cubit, so the auth refresh is
  /// dispatched alongside — it's fire-and-forget, so only the two cubit loads
  /// hold the spinner open.
  Future<void> _onRefresh() async {
    context.read<AuthenticationBloc>().add(RefreshUserRequested());
    await Future.wait([
      context.read<DashboardCubit>().loadStats(silent: true),
      context.read<RecentActivityCubit>().load(silent: true),
    ]);
  }

  /// Kunci halaman pengurus di web (akun dan bank sampahnya), atau null bila
  /// ini bukan pengurus di web. Berubah saat akun berganti, supaya laporan
  /// dimuat ulang.
  String? _webPengurusKey(BuildContext context) {
    if (!(widget.isWeb ?? kIsWeb)) return null;
    return context.select<AuthenticationBloc, String?>((bloc) {
      final state = bloc.state;
      if (state is! Authenticated || state.authEntity.role != 'pengelola') {
        return null;
      }
      return '${state.authEntity.id ?? state.authEntity.email}:'
          '${state.authEntity.bankSampahNama ?? ''}';
    });
  }

  /// Padding area gulir: gutter web di layar lebar, 16 di telepon, ditambah
  /// batas lebar dari `ContentFrame`.
  EdgeInsets _scrollPadding(BuildContext context, {required bool pengurusWeb}) {
    final webGutter =
        pengurusWeb && context.layoutBreakpoint != LayoutBreakpoint.compact;
    return ContentFrame.insetOf(context) +
        (webGutter
            ? const EdgeInsets.fromLTRB(
                AppSpacing.webGutter,
                AppSpacing.webTop,
                AppSpacing.webGutter,
                AppSpacing.xl,
              )
            : const EdgeInsets.all(16.0));
  }

  @override
  Widget build(BuildContext context) {
    final webPengurusKey = _webPengurusKey(context);
    final isPengurusWeb = webPengurusKey != null;

    return Scaffold(
      backgroundColor: isPengurusWeb
          ? WebContentSurface.pageColor(context, phone: AppColors.cardOffWhite)
          : Colors.white,
      body: SafeArea(
        // The scroll view spans the body, so its scrollbar is at the window
        // edge; the frame supplies the side inset that keeps the content to a
        // readable column.
        child: ContentFrame(
          child: AppRefreshIndicator(
            onRefresh: _onRefresh,
            child: Builder(
              builder: (context) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: _scrollPadding(context, pengurusWeb: isPengurusWeb),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Di web lebar profil ada di kaki sidebar, jadi avatar di sini
                    // hanya menggandakannya.
                    DashboardHeader(
                      showProfile: !(isPengurusWeb &&
                          context.layoutBreakpoint != LayoutBreakpoint.compact),
                    ),
                    const SizedBox(height: 24),
                    if (isPengurusWeb)
                      const DashboardWebKpiSection()
                    else ...[
                      const TotalKasCard(),
                      const SizedBox(height: 24),
                      const DashboardStatisticsSection(),
                    ],
                    const SizedBox(height: 24),
                    const DashboardActionButtons(),
                    const SizedBox(height: 32),
                    if (isPengurusWeb) ...[
                      DashboardReportsSection(
                        key: ValueKey('reports-$webPengurusKey'),
                        dataSource: di<DashboardReportingDataSource>(),
                      ),
                      const SizedBox(height: 24),
                      _webDetails(webPengurusKey),
                    ] else
                      const RecentActivitySection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webDetails(String webPengurusKey) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 900
              ? (constraints.maxWidth - 24) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              for (final section in [
                DashboardUpcomingScheduleSection(
                  key: ValueKey('schedule-$webPengurusKey'),
                  repository: di<JadwalRepository>(),
                ),
                const RecentActivitySection(),
              ])
                SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(20), child: section),
                  ),
                ),
            ],
          );
        },
      );
}
