import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/adaptive_surface.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/layout/content_frame.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';

import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/dashboard/analytics/dashboard_analytics.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/states/recent_activity_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
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
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:pilah_mobile/services/di.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, this.isWeb});

  // `kIsWeb` is compile-time constant, so VM tests need this branch override.
  @visibleForTesting
  final bool? isWeb;

  static const route = AppLocations.dashboard;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Provider state must not change during initState's build frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFirst();
    });
  }

  /// Loads what the dashboard shows first, and tells analytics how long that
  /// took and how many of its two parts failed.
  Future<void> _loadFirst() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final analytics = container.read(analyticsClientProvider);
    final watch = Stopwatch()..start();
    await Future.wait([
      container.read(dashboardProvider.notifier).loadStats(),
      // Aktivitas Terbaru has its own notifier — see
      // [RecentActivityNotifier] for why it is not Laporan's feed.
      container.read(recentActivityProvider.notifier).load(),
    ]);
    dashboardLoaded(
      analytics,
      loadTime: watch.elapsed,
      failedSections: [
        container.read(dashboardProvider).status == DashboardStatus.error,
        container.read(recentActivityProvider) is RecentActivityError,
      ].where((failed) => failed).length,
    );
    await _maybePromptLokasi();
  }

  /// One session-scoped nudge for a bank that has no map coordinates yet
  /// (PIL-326 legacy banks). Dismissal is per session — the bank whose
  /// penguru skipped it is asked again next launch, which is the desired
  /// backfill behaviour, needing no "don't ask again" storage.
  ///
  /// The check runs after the first frame because it opens a dialog, and
  /// its bank fetch is best-effort about the session only: a failure returns
  /// null and the dashboard simply shows no prompt rather than an error. A
  /// container without the profile provider registered (shell tests) also
  /// just means no prompt.
  Future<void> _maybePromptLokasi() async {
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      final bank =
          await container.read(profileProvider.notifier).ensureBank();
      if (!mounted || bank == null || bank.lokasi != null) return;
      await _showLokasiPrompt(bank.nama);
    } on Exception catch (_) {
      // No profile provider in this scope: the prompt is untestable noise.
    }
  }

  Future<void> _showLokasiPrompt(String bankNama) {
    return showAdaptiveSurface<void>(
      context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_on_outlined, size: 32),
            const SizedBox(height: 12),
            Text(
              'Lengkapi lokasi bank sampah',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$bankNama belum memasang titik lokasi di peta. Nasabah yang '
              'mencari bank sampah belum dapat menemukannya di peta.',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AppButton(
              key: const Key('prompt_pilih_peta'),
              label: 'Pilih di Peta',
              expand: false,
              onPressed: () async {
                // Everything the save needs is captured before the await so
                // no BuildContext is used across the picker gap.
                final navigator =
                    Navigator.of(sheetContext, rootNavigator: true);
                final container =
                    ProviderScope.containerOf(sheetContext, listen: false);
                final notifier = container.read(profileProvider.notifier);
                // Seed the cache before the await so the save below finds the
                // full profile in state even on first open.
                if (container.read(profileProvider).bankSampah == null) {
                  await notifier.ensureBank();
                }
                final picked = await navigator.push<
                    ({double latitude, double longitude, double radiusKm})>(
                  MaterialPageRoute(
                    builder: (_) => const MapPickerPage(),
                  ),
                );
                if (picked == null) return;
                // Save immediately with the rest of the record untouched —
                // ensureBank() has the full profile in state for the call.
                // The picker always returns the cari-bank trio; the stored
                // coordinate is just the pair.
                final bank = container.read(profileProvider).bankSampah;
                if (bank == null) return;
                await notifier.updateBankSampah(
                  nama: bank.nama,
                  alamat: bank.alamat,
                  noHpPic: bank.noHpPic,
                  lokasi: (
                    latitude: picked.latitude,
                    longitude: picked.longitude
                  ), // radiusKm belongs to cari, not the stored point.
                );
              },
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Nanti',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Refetches everything the dashboard renders. The header's bank sampah name
  /// comes from the cached session rather than provider state, so auth refresh
  /// is dispatched alongside — it's fire-and-forget, so only the dashboard and
  /// activity loads hold the spinner open.
  Future<void> _onRefresh() async {
    ref.read(authenticationProvider.notifier).refreshUser();
    await Future.wait([
      ref.read(dashboardProvider.notifier).loadStats(silent: true),
      ref.read(recentActivityProvider.notifier).load(silent: true),
    ]);
  }

  /// Kunci halaman pengurus di web (akun dan bank sampahnya), atau null bila
  /// ini bukan pengurus di web. Berubah saat akun berganti, supaya laporan
  /// dimuat ulang.
  String? _webPengurusKey(WidgetRef ref) {
    if (!(widget.isWeb ?? kIsWeb)) return null;
    final state = ref.watch(authenticationProvider);
    if (state is! Authenticated || state.authEntity.role != 'pengelola') {
      return null;
    }
    return '${state.authEntity.id ?? state.authEntity.email}:'
        '${state.authEntity.bankSampahNama ?? ''}';
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
    final webPengurusKey = _webPengurusKey(ref);
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
                    DashboardActionButtons(isWeb: widget.isWeb),
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
