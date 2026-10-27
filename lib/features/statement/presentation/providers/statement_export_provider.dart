import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/statement/domain/model/statement_export.dart';
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart';
import 'package:pilah_mobile/services/di.dart';

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

final statementExportProvider =
    NotifierProvider<StatementExportNotifier, StatementExportState>(
  () => StatementExportNotifier(di<StatementUseCases>()),
);

/// Fetches a nasabah activity-statement PDF for the preview button.
class StatementExportNotifier extends Notifier<StatementExportState> {
  StatementExportNotifier(this._useCases);

  final StatementUseCases _useCases;

  @override
  StatementExportState build() => const StatementExportState();

  String? get error => state.error;

  /// Returns the export on success; `null` on failure, recorded in [state].
  Future<StatementExport?> export(String membershipId) async {
    state = const StatementExportState(status: StatementExportStatus.loading);
    final result = await _useCases.exportPdf(membershipId);
    if (!ref.mounted) return null;
    return result.fold(
      (failure) {
        state = StatementExportState(
          status: StatementExportStatus.failure,
          error: failure.displayMessage,
        );
        return null;
      },
      (export) {
        state = StatementExportState(
          status: StatementExportStatus.loaded,
          export: export,
        );
        return export;
      },
    );
  }
}
