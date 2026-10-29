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
