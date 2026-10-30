import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
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

/// Halaman route untuk panel di tepi kanan jendela, di atas halaman yang
/// sedang terbuka.
///
/// Sebuah [Page] yang dideklarasikan sebagai route, **bukan**
/// `showGeneralDialog`. Dialog yang dibuka langsung pada navigator tidak
/// pernah masuk ke daftar route go_router dan karena itu tidak menambah entri
/// riwayat peramban: `history.length` tidak berubah dan URL tetap sama. Akibat
/// yang sebenarnya diukur di peramban pada 30 Oktober 2026: dengan panel
/// terbuka dan formulir sudah terisi, tombol kembali peramban tidak menutup
/// panel dan tidak bertanya apa pun, melainkan mem-pop *halaman di belakang*
/// panel — `#/dashboard` berpindah ke `#/login` dan setoran yang belum
/// tersimpan hilang begitu saja. Justru jalan keluar yang paling mudah
/// tertekan tanpa sengaja yang paling tidak terlindungi.
///
/// Sebagai route sungguhan, panel ini punya URL-nya sendiri, sehingga tombol
/// kembali mem-pop panel lebih dulu, `PopScope` di bawah ini berjalan, dan
/// pertanyaan sebelum isi dibuang ikut berlaku untuk tombol kembali — sama
/// seperti untuk klik di luar panel.
///
/// Sengaja sebuah [Page] polos dengan [PageRoute] sendiri, bukan
/// `CustomTransitionPage` milik go_router: `lib/design/` tidak perlu ikut
/// terikat pada paket router yang kebetulan dipakai aplikasi, dan sebuah
/// [Page] framework tetap dapat dipakai baik oleh go_router maupun oleh
/// `Navigator.push` biasa — yang juga membuatnya dapat diuji tanpa membangun
/// router.
///
/// Seluruh chrome wadah — tempat, lebar, sudut, warna latar, scrim, dan
/// animasi masuk — ada di sini, bukan di dalam [child]. Itulah yang membuat
/// isi formulir dapat dipakai pada panel maupun pada halaman penuh: ia hanya
/// tahu cara menampilkan dirinya.
class SideSheetPage<T> extends Page<T> {
  const SideSheetPage({
    required this.child,
    this.guard,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// Isi panel, tanpa chrome wadah apa pun.
  final Widget child;

  /// Penjaga isian yang belum tersimpan, bila panel ini perlu menjaganya.
  ///
  /// Objek yang sama harus dipasang pada `GoRoute.onExit` route panel, karena
  /// kedua jalan keluar berbeda melewati jalur yang berbeda dan hanya satu
  /// objek yang tahu pertanyaan mana yang sudah dijawab.
  final SideSheetGuard? guard;

  @override
  Route<T> createRoute(BuildContext context) => _SideSheetRoute<T>(this);
}

/// Route milik [SideSheetPage]: tembus pandang, ber-scrim, dan masuk dari tepi
/// kanan.
///
/// [opaque] false adalah syaratnya: halaman di belakang panel harus tetap
/// terpasang dan tetap tergambar, karena seluruh alasan panel ini ada adalah
/// agar halaman itu tidak hilang.
class _SideSheetRoute<T> extends PageRoute<T> {
  _SideSheetRoute(SideSheetPage<T> page) : super(settings: page);

  SideSheetPage<T> get _page => settings as SideSheetPage<T>;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Tutup panel';

  @override
  Color get barrierColor => AppColors.black.withValues(alpha: 0.54);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      PopScope(
        // Selalu false, lalu diputuskan di dalam callback. PopScope menilai
        // canPop saat build, sedangkan formulir baru menjadi kotor jauh setelah
        // panel dibangun, jadi nilai yang dihitung saat build selalu basi.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _page.guard?.handlePopAttempt(context);
        },
        // LayoutBuilder, bukan MediaQuery sekali baca: lebar panel harus ikut
        // berubah ketika jendela peramban diseret sementara panel terbuka, dan
        // membangun ulang dari constraint menjaga state isi tetap hidup.
        child: LayoutBuilder(
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
                child: SafeArea(child: _page.child),
              ),
            ),
          ),
        ),
      );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
}

/// Penjaga isian yang belum tersimpan pada panel samping.
///
/// Satu objek memegang **dua** jalan keluar, karena Flutter dan go_router
/// memakai jalur yang berbeda dan tidak saling tahu:
///
/// * [handlePopAttempt] untuk `PopScope` di dalam panel. Itu yang dilewati
///   klik di luar panel dan tombol Esc, yang keduanya memanggil
///   `Navigator.maybePop`.
/// * [confirmExit] untuk `GoRoute.onExit`. Itu yang dilewati **tombol kembali
///   peramban**, yang tidak mem-pop apa pun: riwayat peramban berpindah,
///   go_router membangun ulang daftar halaman, dan route dicabut secara
///   deklaratif. `PopScope` adalah sebuah `PopEntry` dan hanya `maybePop` yang
///   membacanya, jadi jalan itu melewatkan penjaganya sama sekali — diukur di
///   peramban pada 30 Oktober 2026: panel tertutup dan satu item setoran
///   hilang tanpa pertanyaan apa pun, sementara klik pada scrim pada formulir
///   yang sama tetap bertanya.
///
/// Keduanya memakai satu kunci sekali-pakai, karena begitu `onExit` terpasang
/// go_router menjalankannya untuk **setiap** pop, termasuk pop dari dalam
/// panel (`delegate.dart:150`). Tanpa kunci itu, satu klik pada scrim akan
/// ditanyai dua kali: sekali oleh `PopScope`, sekali lagi oleh `onExit` atas
/// pop yang baru saja disetujui.
class SideSheetGuard {
  SideSheetGuard({required this.hasUnsavedInput});

  /// Dibaca saat panel hendak ditutup, bukan saat dibangun.
  ///
  /// Formulir baru menjadi kotor jauh setelah panel dibangun, jadi nilai yang
  /// dihitung saat build selalu basi.
  final bool Function() hasUnsavedInput;

  bool _answered = false;

  /// Melewatkan pertanyaan untuk satu penutupan berikutnya.
  ///
  /// Dipakai isi panel ketika ia menutup dirinya sendiri sesudah berhasil
  /// menyimpan. Di sana pengguna sudah memutuskan, dan bertanya justru akan
  /// menahan simpan yang baru saja ia minta.
  void allowNextExit() => _answered = true;

  /// Jalan keluar lewat `Navigator.maybePop`: scrim dan Esc.
  Future<void> handlePopAttempt(BuildContext context) async {
    // Navigator diambil sebelum await. Sesudahnya element pemanggil bisa sudah
    // tidak terpasang, dan membacanya dari context yang sudah mati adalah
    // kelas bug yang sama dengan yang pernah muncul pada panel harga dan
    // jadwal.
    final navigator = Navigator.of(context);

    if (!hasUnsavedInput()) {
      allowNextExit();
      navigator.pop();
      return;
    }

    if (!await _askDiscard(context)) return;

    allowNextExit();
    navigator.pop();
  }

  /// Jalan keluar lewat riwayat peramban: dipasang sebagai `GoRoute.onExit`.
  ///
  /// Mengembalikan true bila panel boleh ditinggalkan. Sengaja tidak menerima
  /// `GoRouterState`: `lib/design/` tidak perlu ikut terikat pada paket router
  /// yang kebetulan dipakai aplikasi, dan pemanggilnya tinggal mengabaikan
  /// argumen kedua.
  Future<bool> confirmExit(BuildContext context) async {
    if (_answered) {
      _answered = false;
      return true;
    }
    if (!hasUnsavedInput()) return true;
    return _askDiscard(context);
  }
}

/// Pertanyaannya milik wadah, bukan milik formulir, supaya setiap panel
/// bertanya dengan kalimat yang sama.
Future<bool> _askDiscard(BuildContext context) => showAppConfirmDialog(
      context,
      title: 'Buang isi formulir?',
      message: 'Isi formulir ini belum tersimpan dan akan hilang.',
      confirmLabel: 'Buang',
      cancelLabel: 'Lanjut mengisi',
      destructive: true,
    );
