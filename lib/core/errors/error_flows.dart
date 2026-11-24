/// The core flows of a pengurus, by name, so the team can tell at a glance when
/// an error is in one of the tasks that matter most.
abstract final class ErrorFlows {
  /// The flow the [screen] (named by `AnalyticsScreenTracker.nameFor`) belongs
  /// to, or null when it belongs to none of the core ones. Only the first part
  /// of the name counts, so `riwayat-perubahan-pencairan` is not `riwayat`.
  static String? nameFor(String screen) {
    final first = screen.split('/').first;
    return switch (first) {
      'transaksi-baru' => 'setoran',
      'riwayat' => 'riwayat',
      'login' || 'forgot_password' || 'choose-role' => 'login',
      _ => null,
    };
  }
}
