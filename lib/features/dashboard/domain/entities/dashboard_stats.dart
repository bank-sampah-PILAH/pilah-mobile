/// Current savings and current-month activity from `GET /api/v1/dashboard/stats`.
class DashboardStats {
  /// Monthly deposit value; retained property name for existing callers.
  final int totalKasBulanIni;

  /// Current customer savings, independent of the month. Null means unavailable.
  final int? totalSaldoNasabah;

  /// Active nasabah count (`nasabah_aktif`).
  final int nasabahAktif;

  /// Total weight collected this month in kg (`total_sampah_kg_bulan_ini`).
  final double totalSampahKg;

  /// Number of transactions this month (`transaksi_bulan_ini`).
  final int transaksiBulanIni;

  const DashboardStats({
    this.totalSaldoNasabah,
    required this.totalKasBulanIni,
    required this.nasabahAktif,
    required this.totalSampahKg,
    required this.transaksiBulanIni,
  });
}
