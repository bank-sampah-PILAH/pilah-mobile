import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';

/// Submits an appeal (a resubmission of a rejected membership) from the
/// approval detail page (PIL-232).
///
/// Deliberately `@injectable`, one instance per detail-page visit — like
/// [NasabahApprovalCubit], not app-scoped.
@injectable
class NasabahAppealCubit extends Cubit<NasabahAppealState> {
  final AppealMembershipUseCase appealUseCase;

  NasabahAppealCubit(this.appealUseCase) : super(const NasabahAppealIdle());

  Future<void> submit(String bankSampahId) async {
    emit(const NasabahAppealSubmitting());
    final result = await appealUseCase.execute(bankSampahId);
    result.fold(
      (failure) => emit(NasabahAppealFailure(failure.displayMessage)),
      (_) => emit(const NasabahAppealSuccess()),
    );
  }
}
