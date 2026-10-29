import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/radius.dart';

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
  /// Di bawah batas [sideSheet] tidak ada halaman untuk disisakan, jadi panel
  /// mengisi jendela. Itu bukan jalur yang dipakai telepon — telepon memakai
  /// [fullScreen] dengan route-nya sendiri — melainkan jaring pengaman ketika
  /// jendela peramban diseret menyempit sementara panel sedang terbuka.
  /// Tanpa itu `windowWidth - minPageVisible` menjadi negatif dan layout
  /// melempar.
  static double widthFor(double windowWidth) =>
      windowWidth < LayoutBreakpoint.mediumMinWidth
          ? math.max(windowWidth, 0)
          : math.min(maxWidth, windowWidth - minPageVisible);

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

/// Membuka [builder] sebagai panel di tepi kanan jendela, di atas halaman yang
/// sedang terbuka.
///
/// Seluruh chrome wadah — tempat, lebar, sudut, warna latar, scrim, dan animasi
/// masuk — ada di sini, bukan di dalam [builder]. Itulah yang membuat isi
/// formulir dapat dipakai pada panel maupun pada halaman penuh: ia hanya tahu
/// cara menampilkan dirinya.
///
/// Dibuka pada **root navigator**. Formulir setoran dapat dijangkau dari
/// dashboard, dari rail web, dan dari route-nya sendiri, dan shell tempat
/// ketiganya duduk punya navigator bercabang; panel yang di-push ke navigator
/// cabang akan terpotong oleh cabang itu dan ikut hilang ketika cabangnya
/// berganti.
///
/// Sebuah route sungguhan, bukan [OverlayEntry]: dengan begitu tombol kembali
/// peramban, tombol Esc, dan `Navigator.pop` menutupnya tanpa kode tambahan,
/// dan halaman di belakangnya tidak dapat dinavigasi sementara formulir masih
/// berjalan.
///
/// Mengembalikan nilai yang di-pop oleh isi panel, atau null bila ditutup tanpa
/// hasil.
Future<T?> showSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Tutup panel',
    transitionDuration: const Duration(milliseconds: 220),
    // LayoutBuilder, bukan MediaQuery sekali baca: lebar panel harus ikut
    // berubah ketika jendela peramban diseret sementara panel terbuka, dan
    // membangun ulang dari constraint menjaga state isi tetap hidup.
    pageBuilder: (sheetContext, animation, secondaryAnimation) => LayoutBuilder(
      builder: (layoutContext, constraints) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: SideSheetPresentation.widthFor(constraints.maxWidth),
          height: double.infinity,
          child: Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppRadius.xl),
              ),
            ),
            // Di bawah bilah sistem pada jendela yang punya inset.
            child: SafeArea(child: Builder(builder: builder)),
          ),
        ),
      ),
    ),
    transitionBuilder: (transitionContext, animation, secondary, child) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}
