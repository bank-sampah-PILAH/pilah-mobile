import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';

/// Backs the dashboard's "Aktivitas Terbaru" list.
///
/// Deliberately its own cubit rather than a second reader of `TransaksiCubit`.
/// That one belongs to Laporan, where the period filter is the user's to drive
/// — so picking "Bulan Lalu" there used to silently rewrite what the dashboard
/// called the latest activity, and the dashboard's own load re-scoped Laporan
/// back to `bulan_ini` in return. This cubit answers one fixed question, "the
/// last [limit] transactions, ever", and nothing on Laporan can change it.
@lazySingleton
class RecentActivityCubit extends Cubit<RecentActivityState> {
  final GetTransaksiUseCase getTransaksiUseCase;

  RecentActivityCubit(this.getTransaksiUseCase) : super(RecentActivityInitial());

  /// How many transactions the section shows. Also the requested `page_size`:
  /// the backend returns newest-first, so the first three rows of an unfiltered
  /// list are the three latest transactions.
  static const limit = 3;

  /// Fetches the latest [limit] transactions across all time.
  ///
  /// Pass [silent] to skip the [RecentActivityLoading] emit — pull-to-refresh
  /// already shows a spinner, so the list should stay on screen rather than
  /// collapse under it. It only applies when there is something to keep: from
  /// [RecentActivityInitial] or [RecentActivityError] the section is empty, so
  /// a real loading state is emitted regardless.
  Future<void> load({bool silent = false}) async {
    if (!silent || state is! RecentActivityLoaded) emit(RecentActivityLoading());
    final result = await getTransaksiUseCase.execute(
      const TransaksiFilter.semua(pageSize: limit),
    );
    result.fold(
      (failure) => emit(RecentActivityError(failure.displayMessage)),
      (groups) => emit(RecentActivityLoaded(_takeLatest(groups))),
    );
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() => emit(RecentActivityInitial());

  /// Caps the result at [limit] transactions while keeping the day grouping.
  /// `page_size` already does this server-side; this is what keeps the section
  /// short if that ever stops being true.
  List<TransaksiGroupEntity> _takeLatest(List<TransaksiGroupEntity> groups) {
    final trimmed = <TransaksiGroupEntity>[];
    var remaining = limit;
    for (final group in groups) {
      if (remaining == 0) break;
      final transactions = group.transactions.take(remaining).toList();
      if (transactions.isEmpty) continue;
      remaining -= transactions.length;
      trimmed.add(TransaksiGroupEntity(
        header: group.header,
        transactions: transactions,
      ));
    }
    return trimmed;
  }
}
