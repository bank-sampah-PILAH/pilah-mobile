import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/draft_pencairan.dart';
import '../../domain/repository/draft_pencairan_repository.dart';
import '../states/pilih_nasabah_state.dart';
import 'package:pilah_mobile/services/di.dart';

final pilihNasabahProvider =
    NotifierProvider.autoDispose<PilihNasabahNotifier, PilihNasabahState>(
  () => PilihNasabahNotifier(di<DraftPencairanRepository>()),
);

/// Search, sort, filters and picks for the Nasabah picker.
class PilihNasabahNotifier extends Notifier<PilihNasabahState> {
  PilihNasabahNotifier(this._repository);

  final DraftPencairanRepository _repository;
  int _generation = 0;

  @override
  PilihNasabahState build() => const PilihNasabahState();

  Future<void> load() => _fetch();

  Future<void> setSearch(String search) => _fetch(search: search);

  Future<void> setUrutan(KandidatUrutan urutan) => _fetch(urutan: urutan);

  Future<void> setSortField(KandidatSortField field) =>
      _fetch(urutan: state.urutan.pilih(field));

  void setFilter(PilihFilter filter) => state = state.copyWith(filter: filter);

  void setSaldoMin(int saldoMin) => state = state.copyWith(saldoMin: saldoMin);

  Future<void> _fetch({String? search, KandidatUrutan? urutan}) async {
    final generation = ++_generation;
    final next = state.copyWith(
      search: search,
      urutan: urutan,
      errorMessage: () => null,
    );
    state = state.kandidat.isEmpty
        ? next.copyWith(status: PilihStatus.loading)
        : next;
    final result = await _repository.getKandidat(
      search: next.search,
      urutan: next.urutan,
      termasukKosong: true,
    );
    if (!ref.mounted || generation != _generation) return;
    result.fold(
      (failure) => state = next.copyWith(
        status: PilihStatus.failure,
        errorMessage: () => failure.displayMessage,
      ),
      (rows) => state = next.copyWith(
        status: PilihStatus.loaded,
        kandidat: rows,
        known: _remember(rows),
      ),
    );
  }

  void toggle(String id) {
    final kandidat = state.known[id];
    if (kandidat == null || kandidat.kosong) return;
    final selected = {...state.selectedIds};
    if (!selected.remove(id)) selected.add(id);
    state = state.copyWith(selectedIds: selected);
  }

  void pilihTampil() {
    final dapat = state.dapatDipilih.map((k) => k.id).toSet();
    final semua = state.pilihanTampil == PilihanTampil.semua;
    state = state.copyWith(
      selectedIds: semua
          ? state.selectedIds.difference(dapat)
          : {...state.selectedIds, ...dapat},
    );
  }

  void balikkan() {
    final shown = state.dapatDipilih.map((k) => k.id).toSet();
    state = state.copyWith(
      selectedIds: {
        ...state.selectedIds.difference(shown),
        ...shown.difference(state.selectedIds),
      },
    );
  }

  void kosongkan() => state = state.copyWith(selectedIds: {});

  Map<String, Kandidat> _remember(List<Kandidat> rows) =>
      {...state.known, for (final k in rows) k.id: k};
}
