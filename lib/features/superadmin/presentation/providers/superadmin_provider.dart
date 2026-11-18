import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/presentation/states/superadmin_state.dart';
import 'package:pilah_mobile/services/di.dart';

final superadminProvider =
    NotifierProvider.autoDispose<SuperadminNotifier, SuperadminState>(
  () => SuperadminNotifier(
    di<GetBankSampahUseCase>(),
    di<ApproveBankSampahUseCase>(),
    di<RejectBankSampahUseCase>(),
  ),
);

abstract interface class SuperadminActions {
  Future<NetworkException?> approve(String id);
  Future<NetworkException?> reject(String id);
}

class SuperadminNotifier extends Notifier<SuperadminState>
    implements SuperadminActions {
  SuperadminNotifier(
    this.getBankSampahUseCase,
    this.approveBankSampahUseCase,
    this.rejectBankSampahUseCase,
  );

  final GetBankSampahUseCase getBankSampahUseCase;
  final ApproveBankSampahUseCase approveBankSampahUseCase;
  final RejectBankSampahUseCase rejectBankSampahUseCase;

  String _status = 'pending';

  String get status => _status;

  @override
  SuperadminState build() => SuperadminInitial();

  Future<void> loadBankSampah(String status, {bool silent = false}) async {
    _status = status;
    if (!silent || state is! SuperadminLoaded) state = SuperadminLoading();
    final result = await getBankSampahUseCase.execute(status);
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = SuperadminError(failure.displayMessage),
      (data) => state = SuperadminLoaded(banks: data, status: status),
    );
  }

  @override
  Future<NetworkException?> approve(String id) async {
    final result = await approveBankSampahUseCase.execute(id);
    if (!ref.mounted) return null;
    return result.fold(
      (failure) => failure,
      (_) {
        loadBankSampah(_status);
        return null;
      },
    );
  }

  @override
  Future<NetworkException?> reject(String id) async {
    final result = await rejectBankSampahUseCase.execute(id);
    if (!ref.mounted) return null;
    return result.fold(
      (failure) => failure,
      (_) {
        loadBankSampah(_status);
        return null;
      },
    );
  }
}
