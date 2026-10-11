import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_action_buttons.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_statistics_section.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/total_kas_card.dart';
import 'package:pilah_mobile/features/map/presentation/pages/map_picker_page.dart';
import 'package:pilah_mobile/features/map/presentation/widgets/location_service.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
                final navigator = Navigator.of(sheetContext);
                final cubit = sheetContext.read<ProfileCubit>();
                final picked = await navigator.push<Lokasi>(MaterialPageRoute(
                  builder: (_) => const MapPickerPage(),
                ));
                if (picked == null) return;
                // Save immediately with the rest of the record untouched —
                // ensureBank() has the full profile in state for the call.
                final bank = cubit.state.bankSampah;
                if (bank == null) return;
                await cubit.updateBankSampah(
                  nama: bank.nama,
                  alamat: bank.alamat,
                  noHpPic: bank.noHpPic,
                  lokasi: picked,
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                const TotalKasCard(),
                const SizedBox(height: 24),

                // Statistics Row
                const DashboardStatisticsSection(),
                const SizedBox(height: 24),

                const DashboardActionButtons(),
                const SizedBox(height: 32),

                const RecentActivitySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
