import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_state.dart';

/// Loads the nasabah's announcement list (PIL-244) and flips the read marker
/// when a detail was read.
@lazySingleton
class NasabahPengumumanCubit extends Cubit<NasabahPengumumanState> {
  final NasabahPengumumanRepository repository;

  int _loadVersion = 0;
  bool _isLoadingMore = false;
  String _membershipId = '';

  NasabahPengumumanCubit(this.repository)
      : super(const NasabahPengumumanState());

  Future<void> load({String? membershipId, bool silent = false}) async {
    final version = ++_loadVersion;
    if (membershipId != null) _membershipId = membershipId;
    if (!silent) {
      emit(const NasabahPengumumanState(
          status: NasabahPengumumanStatus.loading));
    }
    try {
      final page = await repository.list(
        membershipId: _membershipId.isEmpty ? null : _membershipId,
        page: 1,
      );
      if (version != _loadVersion) return;
      emit(NasabahPengumumanState(
        status: NasabahPengumumanStatus.loaded,
        items: page.items,
        hasNext: page.hasMore,
        page: 1,
      ));
    } on NasabahApiException catch (error) {
      if (version != _loadVersion) return;
      emit(NasabahPengumumanState(
          status: NasabahPengumumanStatus.failure, error: error.message));
    }
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (current.status != NasabahPengumumanStatus.loaded ||
        !current.hasNext ||
        _isLoadingMore) {
      return;
    }
    _isLoadingMore = true;
    final version = _loadVersion;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await repository.list(
        membershipId: _membershipId.isEmpty ? null : _membershipId,
        page: current.page + 1,
      );
      if (version != _loadVersion) return;
      final existingIds = current.items.map((item) => item.id).toSet();
      emit(current.copyWith(
        status: NasabahPengumumanStatus.loaded,
        items: [
          ...current.items,
          ...page.items.where((item) => existingIds.add(item.id)),
        ],
        hasNext: page.hasMore,
        page: current.page + 1,
        isLoadingMore: false,
      ));
    } on NasabahApiException catch (error) {
      if (version != _loadVersion) return;
      _isLoadingMore = false;
      emit(current.copyWith(isLoadingMore: false, error: error.message));
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Marks an announcement read and updates the local list row without a
  /// refetch, so the unread marker clears the moment the detail closes.
  Future<void> tandaiDibaca(String id) async {
    try {
      await repository.tandaiDibaca(
        id,
        membershipId: _membershipId.isEmpty ? null : _membershipId,
      );
    } on NasabahApiException {
      // The list stays as it is; the next pull-to-refresh reconciles.
      return;
    }
    final current = state;
    if (current.status != NasabahPengumumanStatus.loaded) return;
    emit(current.copyWith(items: [
      for (final item in current.items)
        if (item.id == id && !item.dibaca)
          PengumumanEntity(
            id: item.id,
            bankSampahId: item.bankSampahId,
            judul: item.judul,
            isi: item.isi,
            terbitPada: item.terbitPada,
            masaBerlakuHingga: item.masaBerlakuHingga,
            ditarikPada: item.ditarikPada,
            status: item.status,
            dibaca: true,
            dibacaPada: DateTime.now(),
          )
        else
          item,
    ]));
  }

  void reset() {
    _loadVersion++;
    _isLoadingMore = false;
    _membershipId = '';
    emit(const NasabahPengumumanState());
  }
}
