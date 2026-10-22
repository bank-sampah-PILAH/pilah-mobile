import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_appeal_state.dart';
import 'package:pilah_mobile/services/di.dart';

final nasabahAppealProvider =
    NotifierProvider.autoDispose<NasabahAppealNotifier, NasabahAppealState>(
  () => NasabahAppealNotifier(di<AppealMembershipUseCase>()),
);

class NasabahAppealNotifier extends Notifier<NasabahAppealState> {
  NasabahAppealNotifier(this.appealUseCase);

  final AppealMembershipUseCase appealUseCase;

  @override
  NasabahAppealState build() => const NasabahAppealIdle();

  Future<void> submit(String bankSampahId, {String pesan = ''}) async {
    state = const NasabahAppealSubmitting();
    final result = await appealUseCase.execute(
      AppealMembershipParams(bankSampahId: bankSampahId, pesan: pesan),
    );
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = NasabahAppealFailure(failure.displayMessage),
      (_) => state = const NasabahAppealSuccess(),
    );
  }
}
