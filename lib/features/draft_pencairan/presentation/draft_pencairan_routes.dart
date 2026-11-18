import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_args.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/pilih_nasabah_pencairan_page.dart';

/// Alur pembuatan pencairan: daftar draft, pemilihan nasabah, dan editornya.
///
/// Ketiganya berurutan — daftar membuka pemilihan nasabah, pemilihan nasabah
/// membuka editor — jadi ketiganya adalah satu pintu masuk yang sama dan
/// dibuka atau ditutup bersama-sama.
///
/// Berkas ini memegang route beserta penjaganya supaya yang hilang ketika
/// alurnya dikunci hanya pendaftarannya, bukan **penjaga route-nya**: baris
/// yang membuat editor aman dicapai, yaitu penolakan membuka editor tanpa
/// draft yang jelas (`?id=` untuk draft tersimpan, `extra` untuk draft baru).
/// Dengan begitu penjaga itu tetap ikut dikompilasi dan diuji, dan jalur yang
/// dikunci tidak bisa menyimpang dari jalur yang sebenarnya karena keduanya
/// dibaca dari daftar ini.
///
/// Lihat `pengumumanRoutes` untuk pola yang sama pada fitur Pengumuman.
final draftPencairanRoutes = <GoRoute>[
  GoRoute(
    path: DraftListPage.route,
    name: DraftListPage.route,
    builder: (context, state) => const DraftListPage(),
  ),
  GoRoute(
    path: PilihNasabahPencairanPage.route,
    name: PilihNasabahPencairanPage.route,
    builder: (context, state) => const PilihNasabahPencairanPage(),
  ),
  GoRoute(
    path: DraftEditorPage.route,
    name: DraftEditorPage.route,
    // The editor needs to know which draft. A saved draft is named by the
    // link's ?id=, so a refreshed web tab reopens it; a new draft lives
    // only in extra, and without either there is nothing to show.
    redirect: (context, state) =>
        DraftEditorArgs.fromRoute(state.extra, state.uri.queryParameters) ==
                null
            ? DraftListPage.route
            : null,
    builder: (context, state) => DraftEditorPage(
      args: DraftEditorArgs.fromRoute(state.extra, state.uri.queryParameters)!,
    ),
  ),
];
