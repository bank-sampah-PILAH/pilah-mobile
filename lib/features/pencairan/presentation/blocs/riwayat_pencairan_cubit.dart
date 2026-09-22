import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/riwayat_pencairan_filter.dart';
import '../../domain/use_cases/pencairan_use_cases.dart';
import 'riwayat_pencairan_state.dart';

@Injectable()
class RiwayatPencairanCubit extends Cubit<RiwayatPencairanState> {
  final PencairanUseCases _useCases;

  RiwayatPencairanCubit(this._useCases) : super(const RiwayatPencairanState());

  Future<void> load(RiwayatPencairanFilter filter) async {
    emit(RiwayatPencairanState(
      status: RiwayatStatus.loading,
      filter: filter,
      items: state.items,
    ));
    final result = await _useCases.getRiwayat(filter);
    result.fold(
      (failure) => emit(RiwayatPencairanState(
        status: RiwayatStatus.failure,
        filter: filter,
        errorMessage: failure.displayMessage,
      )),
      (items) => emit(RiwayatPencairanState(
        status: RiwayatStatus.loaded,
        filter: filter,
        items: items,
      )),
    );
  }

  Future<void> setPeriode(RiwayatPeriode periode) async {
    if (periode == state.filter.periode) return;
    await load(state.filter.copyWith(periode: periode));
  }

  Future<void> setSearch(String search) =>
      load(state.filter.copyWith(search: search));
}
