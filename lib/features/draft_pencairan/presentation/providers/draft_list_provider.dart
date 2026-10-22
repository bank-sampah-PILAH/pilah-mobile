import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_state.dart';
import 'package:pilah_mobile/services/di.dart';

final draftListProvider =
    NotifierProvider.autoDispose<DraftListNotifier, DraftListState>(
  () => DraftListNotifier(di<DraftPencairanRepository>()),
);

/// The saved drafts, so a pengurus can come back to one and finish it.
class DraftListNotifier extends Notifier<DraftListState> {
  DraftListNotifier(this._repository);

  final DraftPencairanRepository _repository;

  @override
  DraftListState build() => const DraftListState();

  /// Reloads without clearing the current list while the request is in flight.
  Future<void> load() async {
    if (state.drafts.isEmpty) {
      state = state.copyWith(status: DraftListStatus.loading);
    }
    final result = await _repository.getDrafts();
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = state.copyWith(
        status: DraftListStatus.failure,
        errorMessage: () => failure.displayMessage,
      ),
      (drafts) => state = state.copyWith(
        status: DraftListStatus.loaded,
        drafts: drafts,
        errorMessage: () => null,
      ),
    );
  }

  /// Cancels a draft, then reloads. Returns why it failed, or null on success.
  Future<String?> batalkan(String id) async {
    final result = await _repository.cancelDraft(id);
    if (!ref.mounted) return null;
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) return failure.displayMessage;
    await load();
    return null;
  }

  void setFilter(DraftStatus? filter) =>
      state = state.copyWith(filter: () => filter);

  void setQuery(String query) => state = state.copyWith(query: query);

  /// Orders by [field]; the same field again flips the direction.
  void setUrutan(DraftSortField field) =>
      state = state.copyWith(urutan: state.urutan.pilih(field));
}
