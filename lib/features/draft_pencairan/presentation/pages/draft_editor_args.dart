import '../../domain/model/draft_pencairan.dart';

/// What the editor opens with: a fresh draft for picked nasabah, or a saved
/// draft to resume.
class DraftEditorArgs {
  final List<Kandidat> kandidat;
  final String? draftId;

  const DraftEditorArgs.baru(this.kandidat) : draftId = null;

  const DraftEditorArgs.lanjutkan(String this.draftId) : kandidat = const [];

  /// The editor's args from a route: go_router's [extra] when the app pushed
  /// it, else the saved draft named by the link's `id`, else null.
  static DraftEditorArgs? fromRoute(
    Object? extra,
    Map<String, String> queryParameters,
  ) {
    if (extra is DraftEditorArgs) return extra;
    final id = queryParameters['id'];
    return id == null || id.isEmpty ? null : DraftEditorArgs.lanjutkan(id);
  }
}
