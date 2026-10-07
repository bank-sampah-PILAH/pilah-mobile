/// Kelas lebar layar yang dipakai seluruh layout responsif PILAH.
///
/// Satu-satunya sumber kebenaran untuk pertanyaan "layar ini selebar apa".
/// Jangan memeriksa `MediaQuery...width` dengan angka ajaib di tempat lain;
/// tambahkan atau pakai blok di sini supaya batasnya tidak bercabang.
///
/// Blok mengikuti Material 3 window size class, yang juga menjadi target
/// Flutter sendiri, sehingga perilakunya sejalan dengan komponen Material
/// seperti NavigationBar dan NavigationRail.
enum LayoutBreakpoint {
  /// Telepon. Navigasi tetap memakai bottom navigation yang sudah ada.
  compact,

  /// Tablet.
  medium,

  /// Desktop.
  expanded;

  /// Batas bawah blok `medium`, dalam logical pixel.
  ///
  /// Sama dengan `NasabahStyle.maxWidth` yang sudah ada di design system:
  /// basis kode memang telah memperlakukan 600 sebagai batas lebar konten.
  static const double mediumMinWidth = 600;

  /// Batas bawah blok `expanded`, dalam logical pixel.
  static const double expandedMinWidth = 840;

  /// Mengklasifikasikan [width] logical pixel ke dalam satu blok.
  ///
  /// Batas dimiliki oleh blok yang lebih lebar: tepat 600 adalah [medium] dan
  /// tepat 840 adalah [expanded]. Lebar non-positif diperlakukan sebagai
  /// [compact] agar pemanggil tidak perlu menjaga kondisi degenerate, yang
  /// memang muncul pada frame pertama sebelum ukuran diketahui.
  static LayoutBreakpoint fromWidth(double width) {
    if (width >= expandedMinWidth) return expanded;
    if (width >= mediumMinWidth) return medium;
    return compact;
  }
}
