import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_state.dart';
import 'package:pilah_mobile/services/di.dart';

final nasabahPengumumanProvider = NotifierProvider.autoDispose<
    NasabahPengumumanNotifier, NasabahPengumumanState>(
  () => NasabahPengumumanNotifier(di<NasabahPengumumanRepository>()),
);

class NasabahPengumumanNotifier extends Notifier<NasabahPengumumanState> {
  NasabahPengumumanNotifier(this.repository);

  final NasabahPengumumanRepository repository;
  int _loadVersion = 0;
  bool _isLoadingMore = false;
  String _membershipId = '';

  @override
  NasabahPengumumanState build() => const NasabahPengumumanState();

  Future<void> load({String? membershipId, bool silent = false}) async {
    final version = ++_loadVersion;
    if (membershipId != null) _membershipId = membershipId;
    if (!silent) {
      state =
          const NasabahPengumumanState(status: NasabahPengumumanStatus.loading);
    }
    try {
      final page = await repository.list(
        membershipId: _membershipId.isEmpty ? null : _membershipId,
        page: 1,
      );
      if (!ref.mounted || version != _loadVersion) return;
      state = NasabahPengumumanState(
        status: NasabahPengumumanStatus.loaded,
        items: page.items,
        hasNext: page.hasMore,
        page: 1,
      );
    } on NasabahApiException catch (error) {
      if (!ref.mounted || version != _loadVersion) return;
      state = NasabahPengumumanState(
          status: NasabahPengumumanStatus.failure, error: error.message);
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
    state = current.copyWith(isLoadingMore: true);
    try {
      final page = await repository.list(
        membershipId: _membershipId.isEmpty ? null : _membershipId,
        page: current.page + 1,
      );
      if (!ref.mounted || version != _loadVersion) return;
      final existingIds = current.items.map((item) => item.id).toSet();
      state = current.copyWith(
        status: NasabahPengumumanStatus.loaded,
        items: [
          ...current.items,
          ...page.items.where((item) => existingIds.add(item.id)),
        ],
        hasNext: page.hasMore,
        page: current.page + 1,
        isLoadingMore: false,
      );
    } on NasabahApiException catch (error) {
      if (!ref.mounted || version != _loadVersion) return;
      _isLoadingMore = false;
      state = current.copyWith(isLoadingMore: false, error: error.message);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> tandaiDibaca(String id) async {
    try {
      await repository.tandaiDibaca(
        id,
        membershipId: _membershipId.isEmpty ? null : _membershipId,
      );
    } on NasabahApiException {
      return;
    }
    if (!ref.mounted) return;
    final current = state;
    if (current.status != NasabahPengumumanStatus.loaded) return;
    state = current.copyWith(items: [
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
    ]);
  }
}
