import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';

@lazySingleton
class JadwalCubit extends Cubit<JadwalState> {
  final JadwalRepository repository;

  int _loadVersion = 0;
  int _calendarVersion = 0;
  int _page = 1;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  DateTime? _dateFilter;
  DateTime? _calendarStart;
  DateTime? _calendarEnd;
  Set<DateTime> _scheduledDates = {};

  JadwalCubit(this.repository) : super(const JadwalInitial());

  List<JadwalEntity> get _items =>
      state is JadwalLoaded ? (state as JadwalLoaded).items : const [];

  Future<void> loadJadwal({bool silent = false, DateTime? date}) async {
    final requestedDate = date == null ? null : _dateOnly(date);
    final dateChanged = !_sameDate(requestedDate, _dateFilter);
    _dateFilter = requestedDate;
    _page = 1;
    _hasMore = false;
    _isLoadingMore = false;
    final version = ++_loadVersion;
    final current = state;

    if (dateChanged) {
      emit(JadwalLoaded(
        const [],
        isLoading: true,
        scheduledDates: _scheduledDates,
      ));
    } else if (!silent || current is! JadwalLoaded) {
      emit(const JadwalLoading());
    }

    final result = await repository.getJadwal(page: 1, date: requestedDate);
    if (version != _loadVersion) return;
    result.fold(
      (failure) => emit(JadwalError(failure.displayMessage)),
      (page) {
        _page = 1;
        _hasMore = page.hasMore;
        emit(JadwalLoaded(
          page.items,
          hasMore: page.hasMore,
          totalCount: page.totalCount,
          scheduledDates: _scheduledDates,
        ));
      },
    );
  }

  Future<void> loadNextPage() async {
    final current = state;
    if (current is! JadwalLoaded ||
        !_hasMore ||
        _isLoadingMore ||
        current.isLoading) {
      return;
    }
    _isLoadingMore = true;
    final version = _loadVersion;
    emit(current.copyWith(
      isLoadingMore: true,
      clearLoadingMoreError: true,
    ));

    final result =
        await repository.getJadwal(page: _page + 1, date: _dateFilter);
    if (version != _loadVersion || state is! JadwalLoaded) return;
    _isLoadingMore = false;
    result.fold(
      (failure) {
        final loaded = state as JadwalLoaded;
        emit(loaded.copyWith(
          isLoadingMore: false,
          loadingMoreError: failure.displayMessage,
        ));
      },
      (page) {
        final loaded = state as JadwalLoaded;
        final existingIds = loaded.items.map((item) => item.id).toSet();
        final items = [
          ...loaded.items,
          ...page.items.where((item) => existingIds.add(item.id)),
        ];
        _page++;
        _hasMore = page.hasMore;
        emit(loaded.copyWith(
          items: items,
          hasMore: page.hasMore,
          isLoadingMore: false,
          totalCount: page.totalCount,
          clearLoadingMoreError: true,
        ));
      },
    );
  }

  Future<void> loadCalendarDates({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    final rangeChanged = _calendarStart != start || _calendarEnd != end;
    _calendarStart = start;
    _calendarEnd = end;
    if (rangeChanged) {
      _scheduledDates = {};
      final current = state;
      if (current is JadwalLoaded) {
        emit(current.copyWith(scheduledDates: _scheduledDates));
      }
    }
    final version = ++_calendarVersion;
    final result = await repository.getCalendarDates(start, end);
    if (version != _calendarVersion) return;
    result.fold(
      (_) {},
      (dates) {
        _scheduledDates = dates.map(_dateOnly).toSet();
        final current = state;
        if (current is JadwalLoaded) {
          emit(current.copyWith(scheduledDates: _scheduledDates));
        }
      },
    );
  }

  Future<NetworkException?> saveJadwal(JadwalEntity jadwal) async {
    final current = state is JadwalLoaded ? state as JadwalLoaded : null;
    emit((current ?? JadwalLoaded(_items)).copyWith(isSaving: true));
    final result = jadwal.id.isEmpty
        ? await repository.createJadwal(jadwal)
        : await repository.updateJadwal(jadwal);
    return await result.fold((failure) async {
      final loaded = state is JadwalLoaded ? state as JadwalLoaded : current;
      if (loaded != null) emit(loaded.copyWith(isSaving: false));
      return failure;
    }, (_) async {
      await _reloadAfterMutation();
      return null;
    });
  }

  Future<NetworkException?> changeStatus(String id, String action) async {
    final result = await repository.transition(id, action);
    return result.fold(
      (failure) => failure,
      (_) async {
        await _reloadAfterMutation();
        return null;
      },
    );
  }

  Future<void> _reloadAfterMutation() async {
    await loadJadwal(silent: true, date: _dateFilter);
    final start = _calendarStart;
    final end = _calendarEnd;
    if (start != null && end != null) {
      await loadCalendarDates(startDate: start, endDate: end);
    }
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDate(DateTime? left, DateTime? right) => left == null
      ? right == null
      : right != null && _dateOnly(left) == _dateOnly(right);

  void reset() {
    _loadVersion++;
    _calendarVersion++;
    _page = 1;
    _hasMore = false;
    _isLoadingMore = false;
    _dateFilter = null;
    _calendarStart = null;
    _calendarEnd = null;
    _scheduledDates = {};
    emit(const JadwalInitial());
  }
}
