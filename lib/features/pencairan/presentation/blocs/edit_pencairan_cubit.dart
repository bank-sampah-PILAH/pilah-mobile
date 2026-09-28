import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';

import '../../domain/model/pencairan.dart';
import '../../domain/use_cases/pencairan_use_cases.dart';
import 'edit_pencairan_state.dart';

@Injectable()
class EditPencairanCubit extends Cubit<EditPencairanState> {
  final PencairanUseCases _useCases;

  EditPencairanCubit(this._useCases) : super(const EditPencairanState());

  /// Form fields that can carry their own server-side error.
  static const _fields = ['nominal', 'tanggal', 'alasan'];

  Future<void> submit(EditPencairanRequest request) async {
    // Double-tap guard: an edit can move saldo, so never send it twice.
    if (state.status == EditStatus.submitting) return;
    emit(const EditPencairanState(status: EditStatus.submitting));

    final result = await _useCases.editPencairan(request);
    if (isClosed) return;
    result.fold(
      (failure) {
        final fieldErrors = _fieldErrors(failure);
        emit(EditPencairanState(
          status: EditStatus.failure,
          fieldErrors: fieldErrors,
          errorMessage: fieldErrors.isEmpty ? failure.displayMessage : null,
        ));
      },
      (updated) => emit(
        EditPencairanState(status: EditStatus.success, updated: updated),
      ),
    );
  }

  Map<String, String> _fieldErrors(NetworkException failure) {
    if (failure is! UnprocessableEntityException) return const {};
    return {
      for (final field in _fields)
        if (failure.fieldError([field]) case final message?) field: message,
    };
  }
}
