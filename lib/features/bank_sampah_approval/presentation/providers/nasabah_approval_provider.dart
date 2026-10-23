import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/services/di.dart';

final nasabahApprovalProvider =
    NotifierProvider<NasabahApprovalNotifier, NasabahApprovalState>(
  () => NasabahApprovalNotifier(di<GetNasabahMembershipsUseCase>()),
);

class NasabahApprovalNotifier extends Notifier<NasabahApprovalState> {
  NasabahApprovalNotifier(this._getMembershipsUseCase);

  final GetNasabahMembershipsUseCase _getMembershipsUseCase;
  int _loadVersion = 0;

  @override
  NasabahApprovalState build() => const NasabahApprovalInitial();

  /// Keeps a loaded list visible during pull-to-refresh and ignores stale replies.
  Future<void> load({bool silent = false}) async {
    final version = ++_loadVersion;
    if (!silent || state is! NasabahApprovalLoaded) {
      state = const NasabahApprovalLoading();
    }
    final result = await _getMembershipsUseCase.execute();
    if (!ref.mounted || version != _loadVersion) return;
    result.fold(
      (failure) => state = NasabahApprovalError(failure.displayMessage),
      (memberships) => state = NasabahApprovalLoaded(memberships),
    );
  }
}
