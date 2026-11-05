/// The only property names an analytics event may carry, and the check that
/// keeps personal data out of them.
///
/// Events describe what a pengurus did (which step, how long, how many, what
/// went wrong), never who they are or what is on their screen. A name that is
/// not listed here is refused: in debug builds and tests it fails loudly, in a
/// release build it is quietly left out. To send a new kind of property, add its
/// name below after checking it holds no name, contact detail, money amount or
/// text somebody typed.
abstract final class AnalyticsProps {
  static const allowed = <String>{
    'ada_hasil',
    'aksi',
    'alasan',
    'alasan_gagal',
    'alur_id',
    'bagian',
    'berat_total_kg',
    'berhasil',
    'berhasil_setelahnya',
    'bidang',
    'bidang_diubah',
    'cakupan',
    'cara',
    'dapat_diulang',
    'dari',
    'dilanjutkan',
    'durasi_detik',
    'durasi_isi_item_detik',
    'durasi_langkah_detik',
    'durasi_layar_sebelumnya_detik',
    'durasi_muat_detik',
    'durasi_sejak_dibuka_detik',
    'durasi_sejak_layar_dibuka_detik',
    'environment',
    'error_code',
    'filter',
    'format',
    'halaman_ke',
    'http_status',
    'jenis',
    'jenis_aktivitas',
    'jenis_error',
    'jenis_filter',
    'jenis_sampah',
    'jeda_hari_kelas',
    'jeda_sejak_dibuat_hari_kelas',
    'jumlah_bagian_gagal',
    'jumlah_baris_kelas',
    'jumlah_bidang_diubah',
    'jumlah_dipilih',
    'jumlah_hasil_kelas',
    'jumlah_item',
    'jumlah_item_sisa',
    'jumlah_jenis_berbeda',
    'jumlah_masalah',
    'jumlah_nasabah_kelas',
    'jumlah_pencarian',
    'jumlah_variabel_dipakai',
    'kedalaman',
    'kelas_layar',
    'keputusan',
    'lama_kegiatan_kelas',
    'lama_kustom_hari_kelas',
    'langkah',
    'langkah_terakhir',
    'layar',
    'layar_sebelumnya',
    'masalah',
    'mode',
    'nilai_kelas',
    'penyebab',
    'percobaan_ke',
    'periode',
    'peran',
    'platform',
    'status_sebelumnya',
    'sumber',
    'tampilan',
    'template_wa_dipakai',
    'tugas',
    'variabel_ditambah',
    'versi_app',
    'via',
  };

  static final _email = RegExp(r'[^\s@]+@[^\s@]+\.[^\s@]+');
  static final _phoneShaped = RegExp(r'^[+\d\s\-().]+$');

  /// [properties] without the null values, or a failed assertion for a name
  /// that is not allowed or a value that looks like personal data. In a release
  /// build the offending property is left out instead.
  static Map<String, Object> sanitize(Map<String, Object?> properties) {
    final clean = <String, Object>{};
    for (final MapEntry(:key, :value) in properties.entries) {
      if (value == null) continue;
      final problem = _problemWith(key, value);
      if (problem == null) {
        clean[key] = value;
      } else {
        assert(false, 'Analytics property "$key" refused: $problem');
      }
    }
    return clean;
  }

  static String? _problemWith(String name, Object value) {
    if (!allowed.contains(name)) return 'the name is not on the allowed list';
    if (value is List) {
      for (final item in value) {
        if (item is! String) return 'a list may only hold text';
        final problem = _problemWithText(item);
        if (problem != null) return problem;
      }
      return null;
    }
    if (value is String) return _problemWithText(value);
    if (value is num || value is bool) return null;
    return 'only text, numbers, booleans and lists of text are allowed';
  }

  static String? _problemWithText(String text) {
    if (_email.hasMatch(text)) return 'it looks like an email address';
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9 && _phoneShaped.hasMatch(text)) {
      return 'it looks like a phone number';
    }
    return null;
  }
}
