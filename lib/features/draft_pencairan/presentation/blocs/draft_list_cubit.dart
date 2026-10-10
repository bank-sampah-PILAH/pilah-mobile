import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/use_cases/draft_pencairan_use_cases.dart';
import 'draft_list_state.dart';

/// The saved drafts, so a pengurus can come back to one and finish it.
@injectable
class DraftListCubit extends Cubit<DraftListState> {
  final DraftPencairanUseCases _useCases;

  DraftListCubit(this._useCases) : super(const DraftListState());

  /// Loads or reloads. A reload leaves the current list up until the new one
  /// arrives, so pulling to refresh does not blank the screen.
  Future<void> load() async {
    if (state.drafts.isEmpty) {
      emit(state.copyWith(status: DraftListStatus.loading));
    }
    final result = await _useCases.getDrafts();
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
    final result = await _useCases.cancelDraft(id);
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
