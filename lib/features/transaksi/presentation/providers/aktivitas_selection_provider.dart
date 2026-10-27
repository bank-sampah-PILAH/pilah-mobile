import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Setoran yang sedang dipilih di Riwayat Aktivitas (id transaksi). Null
/// berarti daftar tidak dalam mode pilih. Hanya satu setoran yang bisa dipilih
/// sekarang (memilih banyak sekaligus ada di isu lain), dan hanya setoran;
/// pencairan punya alur ubahnya sendiri.
final aktivitasSelectionProvider =
    NotifierProvider<AktivitasSelectionNotifier, String?>(
  AktivitasSelectionNotifier.new,
);

class AktivitasSelectionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Memilih [id], menggantikan pilihan sebelumnya.
  void select(String id) => state = id;

  /// Memilih [id], atau melepasnya bila sudah terpilih, yang keluar dari mode
  /// pilih.
  void toggle(String id) => state = state == id ? null : id;

  void clear() => state = null;
}
