import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/use_cases/pencairan_use_cases.dart';
import 'pencairan_state.dart';

@Injectable()
class PencairanCubit extends Cubit<PencairanState> {
  final PencairanUseCases _useCases;

  PencairanCubit(this._useCases) : super(const PencairanState());

  Future<void> loadSaldo(String nasabahId) async {
    emit(state.copyWith(saldoStatus: SaldoStatus.loading));
    final result = await _useCases.getSaldo(nasabahId);
    result.fold(
      (failure) => emit(state.copyWith(
        saldoStatus: SaldoStatus.failure,
        errorMessage: failure.displayMessage,
      )),
      (saldo) => emit(state.copyWith(
        saldoStatus: SaldoStatus.loaded,
        saldo: saldo,
      )),
    );
  }

  Future<void> submit(PencairanRequest request) async {
    // Double-tap guard: a pencairan moves money, so never send it twice.
    if (state.submitStatus == SubmitStatus.submitting) return;
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));

    final result = await _useCases.createPencairan(request);
    result.fold(
      (failure) {
        final nominalError = _fieldError(failure, 'nominal');
        emit(state.copyWith(
          submitStatus: SubmitStatus.failure,
          nominalError: nominalError,
          errorMessage: nominalError == null ? failure.displayMessage : null,
        ));
      },
      (created) => emit(state.copyWith(
        submitStatus: SubmitStatus.success,
        created: created,
        saldo: created.saldoSesudah,
      )),
    );
  }

  /// Drops a server-side nominal rejection, so editing the field stops
  /// showing an error about the value the user has already changed.
  void clearNominalError() {
    if (state.nominalError == null) return;
    emit(state.copyWith(nominalError: null));
  }

  /// The first message the API returned for [field] on a 422, if any.
  String? _fieldError(NetworkException failure, String field) {
    if (failure is! UnprocessableEntityException) return null;
    return failure.fieldError([field]);
  }
}
