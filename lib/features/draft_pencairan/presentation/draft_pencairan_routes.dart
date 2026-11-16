import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_args.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/pilih_nasabah_pencairan_page.dart';

/// Alur pembuatan pencairan: daftar draft, pemilihan nasabah, dan editornya.
/// Editor tanpa draft tersimpan (`?id=`) atau draft baru (`extra`) kembali ke
/// daftar, agar tautan langsung tidak membuka editor tanpa data.
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
