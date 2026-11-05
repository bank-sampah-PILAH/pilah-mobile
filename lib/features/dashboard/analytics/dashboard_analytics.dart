import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// A button in the dashboard's quick action area.
enum DashboardQuickAction {
  newTransaction('transaksi_baru'),
  addNasabah('tambah_nasabah');

  const DashboardQuickAction(this.wire);

  /// The fixed name that is sent.
  final String wire;
}

/// The range the pengurus picked for the dashboard reports.
enum DashboardRangeChoice {
  today('hari_ini'),
  week('7_hari'),
  month('30_hari'),
  custom('kustom');

  const DashboardRangeChoice(this.wire);

  /// The fixed name that is sent.
  final String wire;
}

/// A quick action was pressed. Pressing Transaksi Baru only opens the choice
/// of what to record; whether a form was started shows in that form's own
/// events.
void dashboardQuickActionTapped(
  AnalyticsClient client,
  DashboardQuickAction action,
) =>
    client.capture('dashboard_aksi_cepat_ditekan', {'aksi': action.wire});

/// The report range was changed. Which range is sent by name, never its dates;
/// a custom range also says how long it is, in a class ([customDays] counts
/// both ends).
void dashboardRangeChanged(
  AnalyticsClient client,
  DashboardRangeChoice choice, {
  int? customDays,
}) =>
    client.capture('dashboard_periode_diubah', {
      'periode': choice.wire,
      if (customDays != null)
        'lama_kustom_hari_kelas': _lengthClass(customDays),
    });

String _lengthClass(int days) {
  if (days <= 7) return '1_7_hari';
  return days <= 30 ? '8_30_hari' : 'lebih_30_hari';
}

/// The dashboard finished loading what it shows first. It says how long that
/// took and how many of its parts failed, never what they show.
void dashboardLoaded(
  AnalyticsClient client, {
  required Duration loadTime,
  required int failedSections,
}) =>
    client.capture('dashboard_dimuat', {
      'durasi_muat_detik': loadTime.inSeconds,
      'jumlah_bagian_gagal': failedSections,
    });
