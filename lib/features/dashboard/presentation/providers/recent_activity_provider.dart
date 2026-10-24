import 'package:flutter_riverpod/flutter_riverpod.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:pilah_mobile/features/dashboard/presentation/states/recent_activity_state.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_filter.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/services/di.dart';

final recentActivityProvider =
    NotifierProvider<RecentActivityNotifier, RecentActivityState>(
  () => RecentActivityNotifier(
    di<GetTransaksiUseCase>(),
    di<PencairanUseCases>(),
  ),
);

/// Backs the dashboard's independent, all-time activity feed.
class RecentActivityNotifier extends Notifier<RecentActivityState> {
  RecentActivityNotifier(this.getTransaksiUseCase, this.pencairanUseCases);

  final GetTransaksiUseCase getTransaksiUseCase;
  final PencairanUseCases pencairanUseCases;

  /// The section shows and fetches only the newest three activity rows.
  static const limit = 3;

  @override
  RecentActivityState build() => RecentActivityInitial();

  Future<void> load({bool silent = false}) async {
    if (!silent || state is! RecentActivityLoaded) {
      state = RecentActivityLoading();
    }
    final result = await getTransaksiUseCase.execute(
      const TransaksiFilter.semua(pageSize: limit),
    );
    if (!ref.mounted) return;
    await result.fold(
      (failure) async => state = RecentActivityError(failure.displayMessage),
      _loadGroups,
    );
  }

  Future<void> _loadGroups(List<TransaksiGroupEntity> groups) async {
    final pencairanResult = await pencairanUseCases.getRiwayat(
      const RiwayatPencairanFilter(
        periode: RiwayatPeriode.semua,
        limit: limit,
      ),
    );
    if (!ref.mounted) return;

    final setoranItems = [
      for (final group in groups)
        for (final transaction in group.transactions)
          ActivitasEntity.fromTransaksi(transaction),
    ];
    final pencairanItems = pencairanResult.fold(
      (_) => const <ActivitasEntity>[],
      (items) => items.map(ActivitasEntity.fromPencairan).toList(),
    );
    state = RecentActivityLoaded(
      _newestFirst([...setoranItems, ...pencairanItems]),
    );
  }

  List<ActivitasEntity> _newestFirst(List<ActivitasEntity> items) {
    items.sort((a, b) {
      final da = a.tanggal;
      final db = b.tanggal;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return items.take(limit).toList();
  }

  void reset() => state = RecentActivityInitial();
}
