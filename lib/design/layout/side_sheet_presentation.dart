import 'dart:math' as math;

import 'layout_breakpoint.dart';

/// Wadah yang dipakai sebuah formulir panjang pada lebar jendela tertentu.
///
/// Dipisahkan dari widget mana pun supaya aturannya dapat diuji tanpa
/// membangun tree, dan supaya setiap pemanggil menjawab sama alih-alih
/// masing-masing memeriksa MediaQuery.
///
/// Formulir yang memenuhi jendela menghapus konteks tempat ia dibuka: Pengurus
/// kehilangan navigation rail dan daftar yang sedang ia telusuri. Di telepon
/// itu tidak terhindarkan dan memang benar. Di jendela lebar itu sebuah
/// pilihan, dan pilihan yang lebih baik adalah panel di tepi dengan halaman
/// yang tetap terlihat di belakangnya.
///
/// Pembedanya adalah **lebar**, bukan platform, sama seperti
/// `PickerPresentation`. Aturan lead dev — bottom bar di aplikasi, navigasi
/// kiri di peramban — berbicara tentang navigasi yang menetap. Formulir
/// bersifat sementara, dan kedua aturan toh sepakat di tempat yang penting,
/// karena telepon native selalu compact.
enum SideSheetPresentation {
  /// Halaman penuh dengan route-nya sendiri. Benar pada telepon: di lebar itu
  /// tidak ada ruang untuk menyisakan halaman di belakang formulir.
  fullScreen,

  /// Panel yang masuk dari tepi kanan di atas halaman, menyisakan halaman itu
  /// tetap terlihat di belakangnya.
  sideSheet;

  /// Lebar terlebar panel, dalam logical pixel.
  ///
  /// Sedikit di bawah [LayoutBreakpoint.formMaxWidth] (640): panel ini memegang
  /// formulir satu kolom, dan kolom isian yang terlalu lebar justru sulit
  /// dipindai. 560 cukup untuk satu baris jenis sampah — jenis, berat, dan
  /// subtotal — tanpa menutup lebih banyak halaman daripada yang perlu.
  static const double maxWidth = 560;

  /// Bagian jendela yang harus tetap tidak tertutup, dalam logical pixel.
  ///
  /// Inti dari panel ini adalah halaman di belakangnya tetap terlihat. Panel
  /// selebar [maxWidth] pada jendela medium tersempit (600) hanya menyisakan
  /// 40 px, yang terbaca sebagai halaman penuh yang rusak alih-alih sebuah
  /// panel. 160 px cukup untuk memperlihatkan tepi daftar di belakangnya
  /// sehingga jelas halaman itu masih ada dan masih di tempatnya.
  static const double minPageVisible = 160;

  /// Lebar panel untuk jendela selebar [windowWidth] logical pixel.
  ///
  /// Sebuah batas atas sekaligus batas bawah: panel tidak melewati [maxWidth],
  /// dan tidak pernah menutup jendela sampai menyisakan kurang dari
  /// [minPageVisible]. Pada jendela sempit batas keduanyalah yang menentukan,
  /// jadi panel di tablet memang lebih sempit daripada di desktop.
  ///
  /// Hanya bermakna untuk lebar yang mendapat [sideSheet]; di bawah itu tidak
  /// ada panel untuk diukur.
  static double widthFor(double windowWidth) =>
      math.min(maxWidth, windowWidth - minPageVisible);

  /// Mengklasifikasikan [width] logical pixel ke dalam satu wadah.
  ///
  /// Lebar non-positif menjadi [fullScreen], mengikuti
  /// [LayoutBreakpoint.fromWidth], karena frame pertama bisa berjalan sebelum
  /// ukuran diketahui.
  static SideSheetPresentation resolve({required double width}) =>
      LayoutBreakpoint.fromWidth(width) == LayoutBreakpoint.compact
          ? fullScreen
          : sideSheet;
}
