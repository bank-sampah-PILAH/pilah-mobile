import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apakah formulir setoran sedang terbuka sebagai panel samping.
///
/// Ketika formulir adalah sebuah halaman, rail menandai menunya dengan
/// membandingkan path yang sedang aktif. Panel samping tidak mengubah path —
/// itu justru inti perubahannya, halaman di belakangnya tetap halaman yang
/// sama — jadi rail kehilangan satu-satunya petunjuknya dan menu Tambah
/// Transaksi berhenti ikut tersorot.
///
/// Keadaan ini mengembalikan petunjuk itu: dinyalakan selama panel hidup, dan
/// dimatikan ketika panel tertutup, bagaimanapun cara ia tertutup.
class SetoranSheetNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void opened() => state = true;

  void closed() => state = false;
}

final setoranSheetProvider =
    NotifierProvider<SetoranSheetNotifier, bool>(SetoranSheetNotifier.new);
