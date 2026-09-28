import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_state.dart';

/// Per-session membership list for the nasabah-facing "Daftar Approval Bank
/// Sampah" screen (PIL-232).
///
/// Deliberately `@injectable` (a new instance per page visit) rather than
/// `@lazySingleton`: unlike [NasabahCubit] this cubit is not app-scoped, so it
/// needs no logout reset wiring to avoid leaking one user's membership data
/// into the next session.
@injectable
class NasabahApprovalCubit extends Cubit<NasabahApprovalState> {
  final GetNasabahMembershipsUseCase getMembershipsUseCase;
  int _loadVersion = 0;

  NasabahApprovalCubit(this.getMembershipsUseCase)
      : super(const NasabahApprovalInitial());

  /// Loads the caller's memberships. Pass [silent] on pull-to-refresh so an
  /// already-loaded list stays on screen instead of collapsing into skeletons
  /// underneath the refresh spinner — mirrors [NasabahCubit.loadNasabah].
  Future<void> load({bool silent = false}) async {
    final version = ++_loadVersion;
    if (!silent || state is! NasabahApprovalLoaded) {
      emit(const NasabahApprovalLoading());
    }
    final result = await getMembershipsUseCase.execute();
    if (isClosed || version != _loadVersion) return;
    result.fold(
      (failure) => emit(NasabahApprovalError(failure.displayMessage)),
      (memberships) => emit(NasabahApprovalLoaded(memberships)),
    );
  }
}
