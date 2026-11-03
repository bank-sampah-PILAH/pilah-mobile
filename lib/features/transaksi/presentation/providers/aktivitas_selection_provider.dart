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

/// PIL-429: null is browsing; an empty set is selection mode with no choices.
/// Separate from PIL-428's single selection so its edit/void flow stays intact.
final aktivitasBulkSelectionProvider =
    NotifierProvider<AktivitasBulkSelectionNotifier, Set<String>?>(
  AktivitasBulkSelectionNotifier.new,
);

class AktivitasBulkSelectionNotifier extends Notifier<Set<String>?> {
  @override
  Set<String>? build() => null;

  void start() => state = const {};

  void toggle(String id) {
    final selected = state;
    if (selected == null || id.isEmpty) return;
    final updated = {...selected};
    if (!updated.remove(id)) updated.add(id);
    state = Set.unmodifiable(updated);
  }

  /// Drop records no longer visible or selectable after a refresh.
  void retain(Set<String> eligibleIds) {
    final selected = state;
    if (selected == null || selected.every(eligibleIds.contains)) return;
    state = Set.unmodifiable(selected.intersection(eligibleIds));
  }

  void clear() => state = null;
}
