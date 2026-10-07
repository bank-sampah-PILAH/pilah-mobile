import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/riwayat_entities.dart';
import '../../domain/use_cases/riwayat_use_cases.dart';

/// Paginated setoran riwayat for the Tabungan screen (PIL-315 UI refactor).
/// The page widget used to hold this state internally; the cubit moves it
/// out so the state machine is testable and the next feature (period
/// filters, PIL-246) extends it instead of the widget.
enum RiwayatHistoryStatus { initial, loading, loaded, failure }

class RiwayatHistoryState extends Equatable {
  const RiwayatHistoryState({
    this.status = RiwayatHistoryStatus.initial,
    this.activities = const [],
    this.hasNext = false,
    this.page = 0,
    this.error,
  });

  final RiwayatHistoryStatus status;
  final List<RiwayatActivity> activities;
  final bool hasNext;
  final int page;
  final String? error;

  RiwayatHistoryState copyWith({
    RiwayatHistoryStatus? status,
    List<RiwayatActivity>? activities,
    bool? hasNext,
    int? page,
    Object? error = _sentinel,
  }) =>
      RiwayatHistoryState(
        status: status ?? this.status,
        activities: activities ?? this.activities,
        hasNext: hasNext ?? this.hasNext,
        page: page ?? this.page,
        error: error == _sentinel ? this.error : error as String?,
      );

  @override
  List<Object?> get props => [status, activities, hasNext, page, error];
}

const _sentinel = Object();

@Injectable()
class RiwayatHistoryCubit extends Cubit<RiwayatHistoryState> {
  RiwayatHistoryCubit(this._historyUseCase, this._detailUseCase)
      : super(const RiwayatHistoryState());

  final GetRiwayatHistoryUseCase _historyUseCase;
  final GetRiwayatSetoranDetailUseCase _detailUseCase;

  /// The membership this cubit's pages belong to (set by [loadHistory]);
  /// detail loads address the same membership.
  String? membershipId;

  /// Loads [page] (or the next page) and appends, deduping by id so a retry
  /// or refresh overlap cannot duplicate rows.
  Future<void> loadHistory(String membershipId, {bool reset = false}) async {
    this.membershipId = membershipId;
    final requestedPage = reset ? 1 : state.page + 1;
    if (state.status == RiwayatHistoryStatus.loading) return;
    emit(state.copyWith(
      status: RiwayatHistoryStatus.loading,
      activities: reset ? [] : state.activities,
      error: null,
      page: requestedPage,
    ));
    final result = await _historyUseCase.execute(
      RiwayatHistoryParams(membershipId, page: requestedPage),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: RiwayatHistoryStatus.failure,
        error: failure.displayMessage,
      )),
      (history) => emit(state.copyWith(
        status: RiwayatHistoryStatus.loaded,
        activities: [
          ...state.activities
              .where((a) => !history.activities.any((n) => n.id == a.id)),
          ...history.activities,
        ],
        hasNext: history.hasNext,
      )),
    );
  }

  /// Refresh/retry/next-page entry from the UI: reloads the membership the
  /// cubit was loaded for (page +1 when not a reset).
  Future<void> loadHistoryCurrent({bool reset = false}) {
    final membership = membershipId ?? '';
    return loadHistory(membership, reset: reset);
  }

  /// Loads one setoran's itemized detail for the bottom sheet; throws
  /// [NetworkException] so the sheet's own error/retry flow shows it.
  Future<RiwayatSetoranDetail> loadDetail(
    String membershipId,
    String transactionId,
  ) async {
    final result = await _detailUseCase.execute(
      RiwayatSetoranDetailParams(
        membershipId: membershipId,
        transactionId: transactionId,
      ),
    );
    return result.fold(
      (failure) => throw failure,
      (detail) => detail,
    );
  }
}
