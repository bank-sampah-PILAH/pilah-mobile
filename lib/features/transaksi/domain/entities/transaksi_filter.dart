import 'dart:typed_data';

/// Period filter for the transaction list / export, mirroring the backend
/// `periode` values: `hari_ini`, `minggu_ini`, `bulan_ini`, `bulan_lalu`,
/// `custom` (with `dari_tanggal` / `sampai_tanggal`), plus [periodeSemua] for
/// no date filter at all.
class TransaksiFilter {
  /// `periode` value meaning "every transaction, no date filter".
  ///
  /// It has to be sent explicitly: the backend's
  /// `TransactionFilterService.apply_period` defaults a *missing* `periode` to
  /// `hari_ini`, and only leaves the queryset untouched for a value it doesn't
  /// recognise. Omitting the param would quietly scope the request to today.
  static const periodeSemua = 'semua';

  final String periode;
  final DateTime? dariTanggal;
  final DateTime? sampaiTanggal;

  /// Rows to ask the backend for (`page_size`, capped at 100 server-side).
  /// Null leaves it to the caller's default — only the dashboard's short
  /// preview list narrows it.
  final int? pageSize;

  const TransaksiFilter({
    this.periode = 'bulan_ini',
    this.dariTanggal,
    this.sampaiTanggal,
    this.pageSize,
  });

  /// Every transaction ever, newest first — no date filter of any kind.
  const TransaksiFilter.semua({this.pageSize})
      : periode = periodeSemua,
        dariTanggal = null,
        sampaiTanggal = null;

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
