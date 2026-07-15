import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_state.dart';

// Route-scoped: the superadmin screen owns this via BlocProvider and closes it
// on exit, so it must be a fresh instance per navigation (a singleton would be
// reused after close and crash with "emit after close" on re-entry).
@injectable
class SuperadminCubit extends Cubit<SuperadminState> {
  final GetBankSampahUseCase getBankSampahUseCase;
  final ApproveBankSampahUseCase approveBankSampahUseCase;
  final RejectBankSampahUseCase rejectBankSampahUseCase;

  String _status = 'pending';

  SuperadminCubit(
    this.getBankSampahUseCase,
    this.approveBankSampahUseCase,
    this.rejectBankSampahUseCase,
  ) : super(SuperadminInitial());

  String get status => _status;

  /// Fetches the bank sampah list for [status] (`pending`, `active`, `rejected`).
  ///
  /// Pass [silent] to skip the [SuperadminLoading] emit — pull-to-refresh already
  /// shows a spinner, so the list should stay on screen instead of collapsing
  /// into skeletons underneath it.
  Future<void> loadBankSampah(String status, {bool silent = false}) async {
    _status = status;
    if (!silent) emit(SuperadminLoading());
    final result = await getBankSampahUseCase.execute(status);
    result.fold(
      (failure) => emit(SuperadminError(failure.displayMessage)),
      (data) => emit(SuperadminLoaded(banks: data, status: status)),
    );
  }

  /// Approves a bank sampah. Returns `null` on success (current tab reloaded),
  /// otherwise the [NetworkException].
  Future<NetworkException?> approve(String id) async {
    final result = await approveBankSampahUseCase.execute(id);
    return result.fold(
      (failure) => failure,
      (_) {
        loadBankSampah(_status);
        return null;
      },
    );
  }

  Future<NetworkException?> reject(String id) async {
    final result = await rejectBankSampahUseCase.execute(id);
    return result.fold(
      (failure) => failure,
      (_) {
        loadBankSampah(_status);
        return null;
      },
    );
  }
}
