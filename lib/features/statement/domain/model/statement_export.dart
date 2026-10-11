/// One fetched activity-statement PDF (PIL-315), ready to preview or save.
class StatementExport {
  const StatementExport({required this.bytes, required this.filename});

  /// The PDF document itself, exactly as the server rendered it.
  final List<int> bytes;

  /// The filename from the response's Content-Disposition header — the name
  /// the downloaded copy should carry.
  final String filename;
}
