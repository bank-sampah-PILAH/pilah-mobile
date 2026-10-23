import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';

String dashboardSavingsDisplay(DashboardState state) {
  if (state.status == DashboardStatus.initial ||
      state.status == DashboardStatus.loading) {
    return 'Memuat...';
  }
  final savings = state.totalSaldoNasabah;
  if (!state.isLoaded || savings == null) return 'Rp —';
  return CurrencyFormatter.formatRupiah(savings);
}

// No cash ledger exists yet. Never infer cash from customer savings or deposits.
const dashboardOperationalCashDisplay = 'Belum tersedia';
