import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
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
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptLokasi());
  }

  /// One session-scoped nudge for a bank that has no map coordinates yet
  /// (PIL-326 legacy banks). Dismissal is per session — the bank whose
  /// penguru skipped it is asked again next launch, which is the desired
  /// backfill behaviour, needing no "don't ask again" storage.
  ///
  /// The check runs after the first frame because it opens a dialog, and
  /// its bank fetch is best-effort about the session only: a failure returns
  /// null and the dashboard simply shows no prompt rather than an error.
  Future<void> _maybePromptLokasi() async {
    final cubit = context.read<ProfileCubit>();
    final bank = await cubit.ensureBank();
    if (!mounted || bank == null || bank.lokasi != null) return;
    await _showLokasiPrompt(bank.nama);
  }

  Future<void> _showLokasiPrompt(String bankNama) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
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
            FilledButton(
              key: const Key('prompt_pilih_peta'),
              onPressed: () async {
                // Everything the save needs is captured before the await so
                // no BuildContext is used across the picker gap.
                final navigator =
                    Navigator.of(sheetContext, rootNavigator: true);
                final cubit = sheetContext.read<ProfileCubit>();
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
                final bank = cubit.state.bankSampah;
                if (bank == null) return;
                await cubit.updateBankSampah(
                  nama: bank.nama,
                  alamat: bank.alamat,
                  noHpPic: bank.noHpPic,
                  lokasi: (
                    latitude: picked.latitude,
                    longitude: picked.longitude
                  ),
                );
              },
              child: const Text('Pilih di Peta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Nanti'),
            ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final webPengurusKey = (widget.isWeb ?? kIsWeb)
        ? context.select<AuthenticationBloc, String?>((bloc) {
            final state = bloc.state;
            if (state is! Authenticated ||
                state.authEntity.role != 'pengelola') {
              return null;
            }
            return '${state.authEntity.id ?? state.authEntity.email}:'
                '${state.authEntity.bankSampahNama ?? ''}';
          })
        : null;
    final isPengurusWeb = webPengurusKey != null;

    return Scaffold(
      backgroundColor: isPengurusWeb ? AppColors.cardOffWhite : Colors.white,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardHeader(),
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
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: AppColors.grey200.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(20), child: section),
                  ),
                ),
            ],
          );
        },
      );
}
