import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// A button in the dashboard's quick action area.
enum DashboardQuickAction {
  newTransaction('transaksi_baru'),
  addNasabah('tambah_nasabah');

  const DashboardQuickAction(this.wire);

  /// The fixed name that is sent.
  final String wire;
}

/// A preset range the pengurus picked for the dashboard reports. A custom
/// range has its own event function because it must also say how long it is.
enum DashboardRangeChoice {
  today('hari_ini'),
  week('7_hari'),
  month('30_hari');

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

/// A preset report range was chosen. Which range is sent by name, never its
/// dates.
void dashboardRangeChanged(
  AnalyticsClient client,
  DashboardRangeChoice choice,
) =>
    client.capture('dashboard_periode_diubah', {'periode': choice.wire});

/// A custom report range was applied. It says how long it is, in a class
/// ([days] counts both ends), never its dates. The duration is required so no
/// custom event can be sent without it.
void dashboardCustomRangeChanged(
  AnalyticsClient client, {
  required int days,
}) =>
    client.capture('dashboard_periode_diubah', {
      'periode': 'kustom',
      'lama_kustom_hari_kelas': _lengthClass(days),
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
