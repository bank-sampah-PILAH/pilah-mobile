import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';

/// Reloads every view that shows setoran totals after a setoran changed on
/// the server: Riwayat, and the dashboard, recent activity and nasabah saldo
/// when the pengurus already opened them. Screens never opened are not built.
void reloadAfterSetoranChange(ProviderContainer container) {
  container.read(riwayatAktivitasProvider.notifier).load(silent: true);
  if (container.exists(dashboardProvider)) {
    container.read(dashboardProvider.notifier).loadStats(silent: true);
  }
  if (container.exists(recentActivityProvider)) {
    container.read(recentActivityProvider.notifier).load(silent: true);
  }
  if (container.exists(nasabahProvider)) {
    container.read(nasabahProvider.notifier).loadNasabah(silent: true);
  }
}
