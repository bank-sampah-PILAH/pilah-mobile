import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/states/edit_pencairan_state.dart';
import 'package:pilah_mobile/services/di.dart';

final editPencairanProvider =
    NotifierProvider.autoDispose<EditPencairanNotifier, EditPencairanState>(
  () => EditPencairanNotifier(di<PencairanUseCases>()),
);

class EditPencairanNotifier extends Notifier<EditPencairanState> {
  EditPencairanNotifier(this._useCases);

  final PencairanUseCases _useCases;

  static const _fields = ['nominal', 'tanggal', 'alasan'];

  @override
  EditPencairanState build() => const EditPencairanState();

  Future<void> submit(EditPencairanRequest request) async {
    if (state.status == EditStatus.submitting) return;
    state = const EditPencairanState(status: EditStatus.submitting);

    final result = await _useCases.editPencairan(request);
    if (!ref.mounted) return;
    result.fold(
      (failure) {
        final fieldErrors = _fieldErrors(failure);
        state = EditPencairanState(
          status: EditStatus.failure,
          fieldErrors: fieldErrors,
          errorMessage: fieldErrors.isEmpty ? failure.displayMessage : null,
        );
      },
      (updated) => state =
          EditPencairanState(status: EditStatus.success, updated: updated),
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
