import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Setoran yang sedang dipilih di Riwayat Aktivitas (id transaksi). Null
/// berarti tidak ada yang dipilih dan daftar tidak dalam mode pilih; set tidak
/// pernah kosong. Hanya setoran yang masih tercatat yang bisa dipilih;
/// pencairan punya alur ubahnya sendiri.
final aktivitasSelectionProvider =
    NotifierProvider<AktivitasSelectionNotifier, Set<String>?>(
  AktivitasSelectionNotifier.new,
);

class AktivitasSelectionNotifier extends Notifier<Set<String>?> {
  @override
  Set<String>? build() => null;

  /// Memulai pilihan dengan hanya [id], menggantikan yang sebelumnya.
  void select(String id) => state = id.isEmpty ? null : Set.unmodifiable({id});

  /// Menambah [id] ke pilihan, atau melepasnya bila sudah terpilih. Melepas
  /// yang terakhir keluar dari mode pilih.
  void toggle(String id) {
    if (id.isEmpty) return;
    final updated = {...?state};
    if (!updated.remove(id)) updated.add(id);
    state = updated.isEmpty ? null : Set.unmodifiable(updated);
  }

  /// Memilih tepat [ids] (misalnya semua baris yang bisa dipilih di halaman).
  void selectAll(Iterable<String> ids) {
    final all = {...ids}..remove('');
    state = all.isEmpty ? null : Set.unmodifiable(all);
  }

  /// Buang yang sudah tidak terlihat atau tidak bisa dipilih setelah muat ulang.
  void retain(Set<String> eligibleIds) {
    final selected = state;
    if (selected == null || selected.every(eligibleIds.contains)) return;
    final kept = selected.intersection(eligibleIds);
    state = kept.isEmpty ? null : Set.unmodifiable(kept);
  }

  void clear() => state = null;
}
