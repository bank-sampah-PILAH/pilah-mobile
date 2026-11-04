import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// What part of the Riwayat the pengurus filtered by.
enum RiwayatFilterKind {
  periode('periode'),
  tipe('tipe'),
  pencarian('pencarian'),
  reset('reset');

  const RiwayatFilterKind(this.wire);

  /// The fixed name that is sent.
  final String wire;
}

/// A Riwayat filter changed. [value] is a class of value (a period preset, a
/// type, or `kustom` for a range of dates), never the dates or the words that
/// were typed in a search.
void riwayatFilterChanged(
  AnalyticsClient client,
  RiwayatFilterKind kind, {
  String? value,
}) =>
    client.capture('riwayat_filter_diubah', {
      'jenis_filter': kind.wire,
      'nilai_kelas': value,
    });

/// A detail of one activity was opened. [type] is `setoran` or `pencairan`.
void riwayatDetailOpened(AnalyticsClient client, String type) =>
    client.capture('riwayat_detail_dibuka', {'jenis_aktivitas': type});

/// The report was asked for and either prepared or refused. Saving the file
/// is the device's business and is not reported.
void riwayatExported(AnalyticsClient client, {required bool success}) =>
    client.capture('riwayat_diekspor', {'format': 'xlsx', 'berhasil': success});

/// [count] setoran were voided, one by one from a row or several at once from
/// the selection. Nothing is sent when none was.
void riwayatSetoranVoided(
  AnalyticsClient client, {
  required int count,
  required bool bulk,
}) {
  if (count < 1) return;
  client.capture('riwayat_setoran_dibatalkan', {
    'cara': bulk ? 'massal' : 'satuan',
    'jumlah_setoran': count,
  });
}
