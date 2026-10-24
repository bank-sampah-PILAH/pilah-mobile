import 'package:equatable/equatable.dart';

import '../../domain/model/pencairan.dart';

enum EditStatus { idle, submitting, success, failure }

class EditPencairanState extends Equatable {
  final EditStatus status;
  final Pencairan? updated;

  /// Server-side rejections keyed by form field (`nominal`, `tanggal`,
  /// `alasan`), shown inline on that field.
  final Map<String, String> fieldErrors;

  /// Anything else that went wrong, shown as a notification.
  final String? errorMessage;

  const EditPencairanState({
    this.status = EditStatus.idle,
    this.updated,
    this.fieldErrors = const {},
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, updated, fieldErrors, errorMessage];
}
