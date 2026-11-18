/// Jarak dasar aplikasi. Pakai ini alih-alih angka di layar, supaya dua
/// halaman tidak berbeda beberapa piksel.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Jarak kiri dan kanan badan halaman di shell web (layar lebar).
  static const double webGutter = xxl;

  /// Jarak dari tepi atas shell web ke judul halaman.
  static const double webTop = xl;
}
