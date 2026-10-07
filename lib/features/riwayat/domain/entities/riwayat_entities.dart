import 'dart:typed_data';

import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

export 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart'
    show NasabahActivity, NasabahHistory, NasabahSetoranDetail;

/// Layer-local names for the response shapes parsed in the beranda
/// repository file (their single home): riwayat code types against these,
/// avoiding a direct dep on beranda's HTTP class at every call site.
typedef RiwayatHistory = NasabahHistory;
typedef RiwayatSetoranDetail = NasabahSetoranDetail;
typedef RiwayatActivity = NasabahActivity;

/// A fetched statement PDF (PIL-315): raw bytes plus the filename the
/// server picked in Content-Disposition.
class RiwayatPdf {
  const RiwayatPdf({required this.bytes, required this.filename});
  final Uint8List bytes;
  final String filename;
}
