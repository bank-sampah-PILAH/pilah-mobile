import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/harga/domain/entities/versi_harga.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';

enum RiwayatHargaStatus { loading, loaded, failure }

class RiwayatHargaState extends Equatable {
  final RiwayatHargaStatus status;
  final List<VersiHarga> riwayat;
  final String? errorMessage;

  const RiwayatHargaState({
    this.status = RiwayatHargaStatus.loading,
    this.riwayat = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, riwayat, errorMessage];
}

final riwayatHargaProvider =
    NotifierProvider.autoDispose<RiwayatHargaNotifier, RiwayatHargaState>(
  () => RiwayatHargaNotifier(di<GetRiwayatHargaUseCase>()),
);

class RiwayatHargaNotifier extends Notifier<RiwayatHargaState> {
  final GetRiwayatHargaUseCase _getRiwayat;

  RiwayatHargaNotifier(this._getRiwayat);

  @override
  RiwayatHargaState build() => const RiwayatHargaState();

  Future<void> load(String jenisId) async {
    state = const RiwayatHargaState();
    final result = await _getRiwayat.execute(jenisId);
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = RiwayatHargaState(
        status: RiwayatHargaStatus.failure,
        errorMessage: failure.displayMessage,
      ),
      (riwayat) => state = RiwayatHargaState(
        status: RiwayatHargaStatus.loaded,
        riwayat: riwayat,
      ),
    );
  }
}
