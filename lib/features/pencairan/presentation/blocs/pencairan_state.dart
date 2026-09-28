import 'package:equatable/equatable.dart';

import '../../domain/model/pencairan.dart';

enum SaldoStatus { initial, loading, loaded, failure }

enum SubmitStatus { idle, submitting, success, failure }

class PencairanState extends Equatable {
  final SaldoStatus saldoStatus;
  final int saldo;
  final SubmitStatus submitStatus;
  final Pencairan? created;

  /// A server-side rejection of the nominal, shown inline on the field.
  final String? nominalError;

  /// Anything else that went wrong, shown as a notification.
  final String? errorMessage;

  const PencairanState({
    this.saldoStatus = SaldoStatus.initial,
    this.saldo = 0,
    this.submitStatus = SubmitStatus.idle,
    this.created,
    this.nominalError,
    this.errorMessage,
  });

  PencairanState copyWith({
    SaldoStatus? saldoStatus,
    int? saldo,
    SubmitStatus? submitStatus,
    Pencairan? created,
    String? nominalError,
    String? errorMessage,
  }) {
    return PencairanState(
      saldoStatus: saldoStatus ?? this.saldoStatus,
      saldo: saldo ?? this.saldo,
      submitStatus: submitStatus ?? this.submitStatus,
      created: created ?? this.created,
      nominalError: nominalError,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        saldoStatus,
        saldo,
        submitStatus,
        created,
        nominalError,
        errorMessage,
      ];
}
