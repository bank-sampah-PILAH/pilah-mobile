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
  today('1_hari'),
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

/// The report range was changed. Which range is sent by name, never its dates.
void dashboardRangeChanged(
  AnalyticsClient client,
  DashboardRangeChoice choice,
) =>
    client.capture('dashboard_rentang_diubah', {'periode': choice.wire});
