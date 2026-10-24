import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/states/riwayat_pencairan_state.dart';
import 'package:pilah_mobile/services/di.dart';

final riwayatPencairanProvider = NotifierProvider.autoDispose<
    RiwayatPencairanNotifier, RiwayatPencairanState>(
  () => RiwayatPencairanNotifier(di<PencairanUseCases>()),
);

class RiwayatPencairanNotifier extends Notifier<RiwayatPencairanState> {
  RiwayatPencairanNotifier(this._useCases);

  final PencairanUseCases _useCases;

  @override
  RiwayatPencairanState build() => const RiwayatPencairanState();

  Future<void> load(RiwayatPencairanFilter filter) async {
    state = RiwayatPencairanState(
      status: RiwayatStatus.loading,
      filter: filter,
      items: state.items,
    );
    final result = await _useCases.getRiwayat(filter);
    if (!ref.mounted || state.filter != filter) return;
    result.fold(
      (failure) => state = RiwayatPencairanState(
        status: RiwayatStatus.failure,
        filter: filter,
        errorMessage: failure.displayMessage,
      ),
      (items) => state = RiwayatPencairanState(
        status: RiwayatStatus.loaded,
        filter: filter,
        items: items,
      ),
    );
  }

  Future<void> setPeriode(RiwayatPeriode periode) async {
    if (periode == state.filter.periode) return;
    await load(state.filter.copyWith(periode: periode));
  }

  Future<void> setSearch(String search) =>
      load(state.filter.copyWith(search: search));
}
