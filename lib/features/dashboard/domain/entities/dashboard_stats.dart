/// Current-month dashboard metrics from `GET /api/v1/dashboard/stats`.
class DashboardStats {
  /// Total transaction value this month (`total_nilai_bulan_ini`) — "Total Kas".
  final int totalKasBulanIni;

  /// Active nasabah count (`nasabah_aktif`).
  final int nasabahAktif;

  /// Total weight collected this month in kg (`total_sampah_kg_bulan_ini`).
  final double totalSampahKg;

  /// Number of transactions this month (`transaksi_bulan_ini`).
  final int transaksiBulanIni;

  const DashboardStats({
    required this.totalKasBulanIni,
    required this.nasabahAktif,
    required this.totalSampahKg,
    required this.transaksiBulanIni,
  });
}
