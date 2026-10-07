import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/statement_export.dart';
import '../../domain/use_cases/statement_use_cases.dart';

/// One press of the preview button: idle → loading → (loaded | failure).
/// The result navigates instead of rendering, so the state carries the
/// export rather than a UI tree; the button reads it from the call result.
enum StatementExportStatus { idle, loading, loaded, failure }

class StatementExportState extends Equatable {
  const StatementExportState({
    this.status = StatementExportStatus.idle,
    this.export,
    this.error,
  });

  final StatementExportStatus status;
  final StatementExport? export;
  final String? error;

  @override
  List<Object?> get props => [status, export, error];
}

/// Fetches the nasabah activity-statement PDF (PIL-315) and hands it to the
/// caller (the preview button navigates; failure surfaces as [state.error]).
@Injectable()
class StatementExportCubit extends Cubit<StatementExportState> {
  StatementExportCubit(this._useCases) : super(const StatementExportState());

  final StatementUseCases _useCases;

  /// Returns the export on success so the caller can navigate without
  /// rereading state; `null` on failure ([error] then carries the message).
  Future<StatementExport?> export(String membershipId) async {
    emit(const StatementExportState(status: StatementExportStatus.loading));
    final result = await _useCases.exportPdf(membershipId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(StatementExportState(
          status: StatementExportStatus.failure,
          error: failure.displayMessage,
        ));
        return null;
      },
      (export) {
        emit(StatementExportState(
          status: StatementExportStatus.loaded,
          export: export,
        ));
        return export;
      },
    );
  }
}