import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/use_cases/draft_pencairan_use_cases.dart';
import 'pilih_nasabah_state.dart';

/// Picking who to pay out: search, sort, filters and picking in bulk. The
/// server holds the list unpaginated, so what is shown is everyone matching.
@injectable
class PilihNasabahCubit extends Cubit<PilihNasabahState> {
  final DraftPencairanUseCases _useCases;

  /// Only the newest search may land: a slow answer for an older one is dropped.
  int _generation = 0;

  PilihNasabahCubit(this._useCases) : super(const PilihNasabahState());

  Future<void> load() => _fetch();

  Future<void> setSearch(String search) => _fetch(search: search);

  Future<void> setUrutan(KandidatUrutan urutan) => _fetch(urutan: urutan);

  /// Orders by [field]; the same field again flips the direction.
  Future<void> setSortField(KandidatSortField field) =>
      _fetch(urutan: state.urutan.pilih(field));

  void setFilter(PilihFilter filter) => emit(state.copyWith(filter: filter));

  /// Shows only nasabah with at least [saldoMin]; 0 takes the limit off.
  void setSaldoMin(int saldoMin) => emit(state.copyWith(saldoMin: saldoMin));

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
      termasukKosong: true,
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
    final kandidat = state.known[id];
    if (kandidat == null || kandidat.kosong) return;
    final selected = {...state.selectedIds};
    if (!selected.remove(id)) selected.add(id);
    emit(state.copyWith(selectedIds: selected));
  }

  /// Picks everyone shown who has saldo; when they are all picked already, the
  /// same tap un-picks them. Picks the filters are hiding are left alone.
  void pilihTampil() {
    final dapat = state.dapatDipilih.map((k) => k.id).toSet();
    final semua = state.pilihanTampil == PilihanTampil.semua;
    emit(state.copyWith(
      selectedIds: semua
          ? state.selectedIds.difference(dapat)
          : {...state.selectedIds, ...dapat},
    ));
  }

  /// Flips every nasabah on screen who can be picked: picked become unpicked
  /// and the reverse.
  void balikkan() {
    final shown = state.dapatDipilih.map((k) => k.id).toSet();
    emit(state.copyWith(
      selectedIds: {
        ...state.selectedIds.difference(shown),
        ...shown.difference(state.selectedIds),
      },
    ));
  }

  void kosongkan() => emit(state.copyWith(selectedIds: {}));

  Map<String, Kandidat> _remember(List<Kandidat> rows) =>
      {...state.known, for (final k in rows) k.id: k};
}
