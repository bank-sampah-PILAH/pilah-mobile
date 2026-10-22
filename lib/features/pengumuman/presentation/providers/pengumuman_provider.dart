import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';
import 'package:pilah_mobile/features/pengumuman/domain/repositories/pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_state.dart';
import 'package:pilah_mobile/services/di.dart';

final pengumumanProvider =
    NotifierProvider.autoDispose<PengumumanNotifier, PengumumanState>(
  () => PengumumanNotifier(di<PengumumanRepository>()),
);

class PengumumanNotifier extends Notifier<PengumumanState> {
  PengumumanNotifier(this.repository);

  final PengumumanRepository repository;
  bool _saveInProgress = false;
  bool _transitionInProgress = false;
  int _sessionGeneration = 0;
  int _loadVersion = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  String _statusFilter = '';

  @override
  PengumumanState build() => const PengumumanInitial();

  Future<void> loadPengumuman({bool silent = false, String? status}) async {
    final sessionGeneration = _sessionGeneration;
    final requestedFilter = status ?? _statusFilter;
    final filterChanged = requestedFilter != _statusFilter;
    _statusFilter = requestedFilter;
    _page = 1;
    _hasMore = false;
    _isLoadingMore = false;
    final version = ++_loadVersion;

    if (filterChanged || !silent || state is! PengumumanLoaded) {
      state = const PengumumanLoading();
    }

    final result = await repository.getPengumuman(
        page: 1, status: _statusFilter.isEmpty ? null : _statusFilter);
    if (!ref.mounted ||
        version != _loadVersion ||
        sessionGeneration != _sessionGeneration) {
      return;
    }
    result.fold(
      (failure) => state = PengumumanError(failure.displayMessage),
      (page) {
        _page = 1;
        _hasMore = page.hasMore;
        state = PengumumanLoaded(
          page.items,
          isSaving: _saveInProgress,
          isTransitioning: _transitionInProgress,
          hasMore: page.hasMore,
          totalCount: page.totalCount,
          statusFilter: _statusFilter,
        );
      },
    );
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! PengumumanLoaded ||
        !_hasMore ||
        _isLoadingMore ||
        current.isLoading) {
      return;
    }
    _isLoadingMore = true;
    final sessionGeneration = _sessionGeneration;
    final version = _loadVersion;
    state = current.copyWith(isLoadingMore: true, clearLoadingMoreError: true);

    final result = await repository.getPengumuman(
      page: _page + 1,
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    if (!ref.mounted ||
        sessionGeneration != _sessionGeneration ||
        version != _loadVersion ||
        state is! PengumumanLoaded) {
      return;
    }
    _isLoadingMore = false;
    result.fold(
      (failure) {
        final loaded = state as PengumumanLoaded;
        state = loaded.copyWith(
          isLoadingMore: false,
          loadingMoreError: failure.displayMessage,
        );
      },
      (page) {
        final loaded = state as PengumumanLoaded;
        final items = [...loaded.items];
        final existingIds = loaded.items.map((item) => item.id).toSet();
        for (final item in page.items) {
          if (existingIds.add(item.id)) items.add(item);
        }
        _page++;
        _hasMore = page.hasMore;
        state = loaded.copyWith(
          items: items,
          hasMore: page.hasMore,
          isLoadingMore: false,
          totalCount: page.totalCount,
          clearLoadingMoreError: true,
        );
      },
    );
  }

  Future<Either<NetworkException, PengumumanEntity>> savePengumuman(
    PengumumanEntity pengumuman,
  ) async {
    if (_saveInProgress || _transitionInProgress) {
      return Left(GeneralException(
        message: 'Tunggu proses pengumuman selesai sebelum menyimpan.',
      ));
    }

    final generation = _sessionGeneration;
    final current =
        state is PengumumanLoaded ? state as PengumumanLoaded : null;
    _saveInProgress = true;
    try {
      state = (current ?? const PengumumanLoaded([])).copyWith(isSaving: true);
      final result = pengumuman.id.isEmpty
          ? await repository.createPengumuman(pengumuman)
          : await repository.updatePengumuman(pengumuman);
      final reloadNeeded =
          ref.mounted && generation == _sessionGeneration && result.isRight();
      final Either<NetworkException, PengumumanEntity> outcome =
          await result.fold(
        (failure) async => Left(failure),
        (saved) async {
          if (reloadNeeded) {
            await loadPengumuman(silent: true, status: _statusFilter);
          }
          return Right(saved);
        },
      );
      if (!ref.mounted || generation != _sessionGeneration) {
        return outcome.fold(
          (failure) => Left(failure),
          (_) => Left(GeneralException(
              message: 'Sesi berubah, simpan ulang pengumuman.')),
        );
      }
      return outcome;
    } finally {
      if (ref.mounted && generation == _sessionGeneration) {
        _saveInProgress = false;
        final latest = state;
        if (latest is PengumumanLoaded && latest.isSaving) {
          state = latest.copyWith(isSaving: false);
        }
      }
    }
  }

  Future<NetworkException?> terbitkan(
    String id, {
    DateTime? terbitPada,
    DateTime? masaBerlakuHingga,
  }) async {
    if (_transitionInProgress || _saveInProgress) return null;
    return _transition(() => repository.terbitkan(
          id,
          terbitPada: terbitPada,
          masaBerlakuHingga: masaBerlakuHingga,
        ));
  }

  Future<NetworkException?> tarik(String id) async {
    if (_transitionInProgress || _saveInProgress) return null;
    return _transition(() => repository.tarik(id));
  }

  Future<NetworkException?> deletePengumuman(String id) async {
    if (_transitionInProgress || _saveInProgress) return null;
    return _transition(() => repository.deletePengumuman(id));
  }

  Future<NetworkException?> _transition<T>(
    Future<Either<NetworkException, T>> Function() action,
  ) async {
    final generation = _sessionGeneration;
    final current = state;
    _transitionInProgress = true;
    if (current is PengumumanLoaded) {
      state = current.copyWith(isTransitioning: true);
    }
    try {
      final result = await action();
      if (!ref.mounted || generation != _sessionGeneration) {
        return result.fold((failure) => failure, (_) => null);
      }
      return await result.fold(
        (failure) async => failure,
        (_) async {
          await loadPengumuman(silent: true, status: _statusFilter);
          return null;
        },
      );
    } finally {
      if (ref.mounted && generation == _sessionGeneration) {
        _transitionInProgress = false;
        final latest = state;
        if (latest is PengumumanLoaded && latest.isTransitioning) {
          state = latest.copyWith(isTransitioning: false);
        }
      }
    }
  }

  void reset() {
    _sessionGeneration++;
    _loadVersion++;
    _saveInProgress = false;
    _transitionInProgress = false;
    _page = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _statusFilter = '';
    state = const PengumumanInitial();
  }
}
