/// Nama bank sampah sebagaimana ditampilkan pada kepala navigasi.
///
/// Rail dan drawer dulu menuliskan aturan yang sama secara terpisah, dan
/// aturan yang digandakan adalah aturan yang akan menyimpang: mengubah
/// fallback di satu tempat tidak akan terlihat di tempat lain. Satu sumber,
/// dipakai keduanya.
abstract final class BankSampahLabel {
  /// Dipakai ketika sesi tidak membawa nama bank sampah, atau membawa nama
  /// yang hanya berisi spasi.
  static const fallback = 'Bank Sampah';

  static String of(String? nama) {
    final trimmed = nama?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  /// Inisial dari maksimal dua kata pertama, untuk rail yang collapsed.
  static String initialsOf(String? nama) {
    final words = of(nama)
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'BS';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}
