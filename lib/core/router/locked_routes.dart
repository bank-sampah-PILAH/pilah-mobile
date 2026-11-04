import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';

/// Penguncian fitur di tingkat route, untuk fitur yang ditutup menjelang
/// handover (PIL-392): jalurnya **tetap dideklarasikan**, tetapi yang berdiri
/// di sana bukan halamannya melainkan pengalihan.
///
/// Jalurnya tidak dihapus karena route yang tidak dikenal memunculkan layar
/// *page not found* milik go_router, dan PIL-392 melarang pesan error sama
/// kerasnya dengan melarang halamannya. [AppLocations.dashboard] kemudian
/// melewati redirect peran yang global, jadi nasabah yang mengikuti tautan
/// basi diantar ke berandanya sendiri, bukan ke halaman staf.
///
/// Pengganti ini sengaja **tidak** memakai `redirect` route aslinya: penjaga
/// asli mengalihkan ke halaman lain di dalam fiturnya sendiri (editor draft ke
/// daftar draft, misalnya), yang ikut terkunci, sehingga menyalinnya hanya
/// menambah satu lompatan sebelum sampai ke tempat yang sama.
///
/// Dipakai oleh Pengumuman (PIL-436) dan draft Pencairan (PIL-434).
GoRoute lockedRoute(String path, {String to = AppLocations.dashboard}) =>
    GoRoute(path: path, redirect: (_, __) => to);

/// Versi daftar dari [lockedRoute], dibaca dari daftar route fitur yang
/// sebenarnya (lihat `pengumumanRoutes`, `draftPencairanRoutes`).
///
/// Jalur yang dikunci dibaca dari daftar yang sama dengan jalur yang
/// sesungguhnya, jadi keduanya tidak bisa menyimpang; dan membuka kembali
/// sebuah fitur berarti mendaftarkan daftarnya menggantikan pemanggilan ini.
List<GoRoute> lockedRoutes(
  Iterable<GoRoute> routes, {
  String to = AppLocations.dashboard,
}) =>
    [for (final route in routes) lockedRoute(route.path, to: to)];
