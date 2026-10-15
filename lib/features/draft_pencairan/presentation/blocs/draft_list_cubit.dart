import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/repository/draft_pencairan_repository.dart';
import 'draft_list_state.dart';

/// The saved drafts, so a pengurus can come back to one and finish it.
@injectable
class DraftListCubit extends Cubit<DraftListState> {
  final DraftPencairanRepository _repository;

  DraftListCubit(this._repository) : super(const DraftListState());

  /// Loads or reloads. A reload leaves the current list up until the new one
  /// arrives, so pulling to refresh does not blank the screen.
  Future<void> load() async {
    if (state.drafts.isEmpty) {
      emit(state.copyWith(status: DraftListStatus.loading));
    }
    final result = await _repository.getDrafts();
    result.fold(
      (failure) => emit(state.copyWith(
        status: DraftListStatus.failure,
        errorMessage: () => failure.displayMessage,
      )),
      (drafts) => emit(state.copyWith(
        status: DraftListStatus.loaded,
        drafts: drafts,
        errorMessage: () => null,
      )),
    );
  }

  /// Cancels a draft, then reloads. Returns why it failed, or null on success.
  Future<String?> batalkan(String id) async {
    final result = await _repository.cancelDraft(id);
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) return failure.displayMessage;
    await load();
    return null;
  }

  void setFilter(DraftStatus? filter) =>
      emit(state.copyWith(filter: () => filter));

  void setQuery(String query) => emit(state.copyWith(query: query));

  /// Orders by [field]; the same field again flips the direction.
  void setUrutan(DraftSortField field) =>
      emit(state.copyWith(urutan: state.urutan.pilih(field)));
}
