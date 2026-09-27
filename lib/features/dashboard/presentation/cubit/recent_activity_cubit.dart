import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_state.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';

/// Backs the dashboard's "Aktivitas Terbaru" list.
///
/// Deliberately its own cubit rather than a second reader of `TransaksiCubit`.
/// That one belongs to Laporan, where the period filter is the user's to drive
/// — so picking "Bulan Lalu" there used to silently rewrite what the dashboard
/// called the latest activity, and the dashboard's own load re-scoped Laporan
/// back to `bulan_ini` in return. This cubit answers one fixed question, "the
/// last [limit] activity, ever", and nothing on Laporan can change it.
///
/// Merges setoran and pencairan (PIL-282), same as `RiwayatAktivitasCubit`,
/// but kept separate from it for the same reason it's separate from
/// `TransaksiCubit`: that one is period-scoped for the Laporan screen, this
/// one is always "the latest few, full stop".
@lazySingleton
class RecentActivityCubit extends Cubit<RecentActivityState> {
  final GetTransaksiUseCase getTransaksiUseCase;
  final PencairanUseCases pencairanUseCases;

  RecentActivityCubit(this.getTransaksiUseCase, this.pencairanUseCases)
      : super(RecentActivityInitial());

  /// How many activity rows the section shows. Also the requested `page_size`
  /// for setoran: the backend returns newest-first, so the first three rows
  /// of an unfiltered list are the three latest transactions.
  static const limit = 3;

  /// Fetches the latest [limit] activity (setoran and pencairan) across all
  /// time.
  ///
  /// Pass [silent] to skip the [RecentActivityLoading] emit — pull-to-refresh
  /// already shows a spinner, so the list should stay on screen rather than
  /// collapse under it. It only applies when there is something to keep: from
  /// [RecentActivityInitial] or [RecentActivityError] the section is empty, so
  /// a real loading state is emitted regardless.
  Future<void> load({bool silent = false}) async {
    if (!silent || state is! RecentActivityLoaded) {
      emit(RecentActivityLoading());
    }
    final result = await getTransaksiUseCase.execute(
      const TransaksiFilter.semua(pageSize: limit),
    );
    await result.fold(
      (failure) async {
        if (isClosed) return;
        emit(RecentActivityError(failure.displayMessage));
      },
      (groups) async {
        final pencairanResult = await pencairanUseCases.getRiwayat(
          const RiwayatPencairanFilter(periode: RiwayatPeriode.semua),
        );
        if (isClosed) return;

        final setoranItems = [
          for (final group in groups)
            for (final t in group.transactions) ActivitasEntity.fromTransaksi(t),
        ];
        // A failed pencairan fetch degrades to "setoran only" rather than
        // hiding a feed that did load.
        final pencairanItems = pencairanResult.fold(
          (_) => const <ActivitasEntity>[],
          (items) => items.map(ActivitasEntity.fromPencairan).toList(),
        );

        final merged = [...setoranItems, ...pencairanItems]
          ..sort((a, b) {
            final da = a.tanggal;
            final db = b.tanggal;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });

        emit(RecentActivityLoaded(merged.take(limit).toList()));
      },
    );
  }

  /// Clears cached data and resets to the initial state (used on logout, since
  /// this cubit is an app-scoped singleton that outlives a session).
  void reset() => emit(RecentActivityInitial());
}
