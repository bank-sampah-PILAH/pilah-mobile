import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_detail_page.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_form_page.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_page.dart';

/// Route Pengumuman beserta penjaganya, **sengaja tidak didaftarkan**.
///
/// Pengumuman dikunci untuk handover (PIL-436): `app_router_config` memasang
/// redirect untuk setiap `path` di daftar ini, bukan builder-nya. Daftarnya
/// tetap ada di sini, bukan di riwayat git, karena yang hilang bersama builder
/// bukan hanya halamannya melainkan **penjaga route-nya** — baris yang membuat
/// halaman itu aman dicapai:
///
/// * detail menolak tautan basi yang tidak membawa barisnya;
/// * formulir menolak dibuka tanpa argumen;
/// * daftar membaca `keanggotaan_id`, yang diperlukan nasabah dengan dua bank
///   agar tidak mendapat 422.
///
/// Dengan begitu penjaga-penjaga itu tetap ikut dikompilasi dan diuji
/// (`test/features/pengumuman/presentation/pengumuman_routes_test.dart`), dan
/// jalur yang dikunci tidak bisa menyimpang dari jalur yang sebenarnya karena
/// keduanya dibaca dari daftar yang sama.
///
/// **Membuka kembali fiturnya:** daftarkan daftar ini menggantikan redirect di
/// `app_router_config`. Kelola Pengumuman (`PengumumanKelolaPage`) tidak ada di
/// sini karena ia sebuah `StatefulShellBranch`, bukan route tingkat atas;
/// memulihkannya berarti mengembalikan branch itu beserta destinasi rail-nya,
/// jadi tetap satu langkah manual.
final pengumumanRoutes = <GoRoute>[
  GoRoute(
    path: PengumumanPage.route,
    name: PengumumanPage.route,
    builder: (context, state) => PengumumanPage(
      membershipId: state.uri.queryParameters['keanggotaan_id'],
    ),
  ),
  GoRoute(
    path: PengumumanDetailPage.route,
    name: PengumumanDetailPage.route,
    // Without the row (a stale link) there is nothing to show.
    redirect: (context, state) =>
        state.extra is PengumumanEntity ? null : PengumumanPage.route,
    builder: (context, state) => PengumumanDetailPage(
      pengumuman: state.extra! as PengumumanEntity,
    ),
  ),
  GoRoute(
    path: PengumumanFormPage.route,
    name: PengumumanFormPage.route,
    // Without args (a stale link, or a router restored on its own) there
    // is nothing to edit, so fall back to the dashboard.
    redirect: (context, state) =>
        state.extra is PengumumanFormArgs ? null : AppLocations.dashboard,
    builder: (context, state) =>
        PengumumanFormPage(args: state.extra! as PengumumanFormArgs),
  ),
];
