import 'layout_breakpoint.dart';

/// Bentuk navigasi utama sebuah layar.
///
/// Platform menentukan keluarganya, lebar hanya menentukan seberapa banyak
/// navigasi kiri yang ditampilkan. Di aplikasi navigasi selalu berada di bawah;
/// di browser selalu di sebelah kiri, sekalipun jendelanya sempit.
enum NavigationForm {
  /// Bottom navigation bar. Satu-satunya bentuk di aplikasi native.
  bottomBar,

  /// Navigasi tersembunyi di balik tombol menu, dibuka sebagai overlay.
  /// Dipakai di browser yang terlalu sempit untuk rail dan konten sekaligus.
  drawer,

  /// Rail ikon tanpa lebar untuk label di samping.
  railCollapsed,

  /// Rail dengan label di samping ikon.
  railExtended;

  /// Bentuk untuk [isWeb] pada lebar [width].
  ///
  /// Native mengabaikan [width] sepenuhnya: telepon yang dimiringkan lebih
  /// lebar dari banyak desktop, tetapi tetap sebuah telepon.
  static NavigationForm resolve({required bool isWeb, required double width}) {
    if (!isWeb) return bottomBar;
    return switch (LayoutBreakpoint.fromWidth(width)) {
      LayoutBreakpoint.compact => drawer,
      LayoutBreakpoint.medium => railCollapsed,
      LayoutBreakpoint.expanded => railExtended,
    };
  }

  /// `true` bila destinasi disembunyikan sampai pengguna membukanya.
  bool get isOverlay => this == drawer;

  /// `true` bila bentuknya adalah rail di sisi kiri.
  bool get isRail => this == railCollapsed || this == railExtended;
}
