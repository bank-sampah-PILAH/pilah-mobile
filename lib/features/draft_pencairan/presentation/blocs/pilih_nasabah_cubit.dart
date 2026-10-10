import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/use_cases/draft_pencairan_use_cases.dart';
import 'pilih_nasabah_state.dart';

/// Picking who to pay out: search, sort and the quick selects. The server
/// holds the list unpaginated, so "select all" really means everyone.
@injectable
class PilihNasabahCubit extends Cubit<PilihNasabahState> {
  final DraftPencairanUseCases _useCases;

  /// Only the newest search may land: a slow answer for an older one is dropped.
  int _generation = 0;

  PilihNasabahCubit(this._useCases) : super(const PilihNasabahState());

  Future<void> load() => _fetch();

  Future<void> setSearch(String search) => _fetch(search: search);

  Future<void> setUrutan(KandidatUrutan urutan) => _fetch(urutan: urutan);

  Future<void> _fetch({String? search, KandidatUrutan? urutan}) async {
    final generation = ++_generation;
    final next = state.copyWith(
      search: search,
      urutan: urutan,
      errorMessage: () => null,
    );
    emit(state.kandidat.isEmpty
        ? next.copyWith(status: PilihStatus.loading)
        : next);
    final result = await _useCases.getKandidat(
      search: next.search,
      urutan: next.urutan,
    );
    if (generation != _generation) return;
    result.fold(
      (failure) => emit(next.copyWith(
        status: PilihStatus.failure,
        errorMessage: () => failure.displayMessage,
      )),
      (rows) => emit(next.copyWith(
        status: PilihStatus.loaded,
        kandidat: rows,
        known: _remember(rows),
      )),
    );
  }

  void toggle(String id) {
    final selected = {...state.selectedIds};
    if (!selected.remove(id)) selected.add(id);
    emit(state.copyWith(selectedIds: selected));
  }

  /// Everyone who can be paid out, whatever the search is showing.
  Future<void> pilihSemua() async {
    final result = await _useCases.getKandidat();
    result.fold(
      (failure) =>
          emit(state.copyWith(errorMessage: () => failure.displayMessage)),
      (rows) => emit(state.copyWith(
        selectedIds: {...state.selectedIds, ...rows.map((k) => k.id)},
        known: _remember(rows),
        errorMessage: () => null,
      )),
    );
  }

  void kosongkan() => emit(state.copyWith(selectedIds: {}));

  Map<String, Kandidat> _remember(List<Kandidat> rows) =>
      {...state.known, for (final k in rows) k.id: k};
}
