import 'dart:typed_data';

/// Period filter for the transaction list / export, mirroring the backend
/// `periode` values: `hari_ini`, `minggu_ini`, `bulan_ini`, `bulan_lalu`,
/// `custom` (with `dari_tanggal` / `sampai_tanggal`).
class TransaksiFilter {
  final String periode;
  final DateTime? dariTanggal;
  final DateTime? sampaiTanggal;

  const TransaksiFilter({
    this.periode = 'bulan_ini',
    this.dariTanggal,
    this.sampaiTanggal,
  });

  bool get isCustom => periode == 'custom';

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'periode': periode};
    if (isCustom) {
      if (dariTanggal != null) params['dari_tanggal'] = _iso(dariTanggal!);
      if (sampaiTanggal != null) params['sampai_tanggal'] = _iso(sampaiTanggal!);
    }
    return params;
  }

  static String _iso(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
}

/// The downloaded XLSX export: raw bytes plus the server-provided filename.
class TransaksiExport {
  final Uint8List bytes;
  final String filename;

  const TransaksiExport({required this.bytes, required this.filename});
}
