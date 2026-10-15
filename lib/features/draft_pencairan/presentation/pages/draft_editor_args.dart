import '../../domain/model/draft_pencairan.dart';

/// What the editor opens with: a fresh draft for picked nasabah, or a saved
/// draft to resume.
class DraftEditorArgs {
  final List<Kandidat> kandidat;
  final String? draftId;

  const DraftEditorArgs.baru(this.kandidat) : draftId = null;

  const DraftEditorArgs.lanjutkan(String this.draftId) : kandidat = const [];
}
