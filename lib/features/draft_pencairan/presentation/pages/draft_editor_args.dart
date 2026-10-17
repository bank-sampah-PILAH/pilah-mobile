import '../../domain/model/draft_pencairan.dart';

/// What the editor opens with: a fresh draft for picked nasabah, or a saved
/// draft to resume.
class DraftEditorArgs {
  final List<Kandidat> kandidat;
  final String? draftId;

  const DraftEditorArgs.baru(this.kandidat) : draftId = null;

  const DraftEditorArgs.lanjutkan(String this.draftId) : kandidat = const [];

  /// What a draft id looks like: letters, digits, `-` and `_`, as a UUID or a
  /// slug. Anything else in a link is not a draft id.
  static final _idDraft = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// The editor's args from a route: go_router's [extra] when the app pushed
  /// it, else the saved draft named by the link's `id`, else null.
  ///
  /// The id ends up in request paths (`draft-pencairan/<id>/konfirmasi`), so
  /// one from a link must be a bare id: a `/` or `..` would point the
  /// pengurus's own authenticated requests somewhere else (OWASP A01, A03).
  static DraftEditorArgs? fromRoute(
    Object? extra,
    Map<String, String> queryParameters,
  ) {
    if (extra is DraftEditorArgs) return extra;
    final id = queryParameters['id'];
    return id != null && _idDraft.hasMatch(id)
        ? DraftEditorArgs.lanjutkan(id)
        : null;
  }
}
