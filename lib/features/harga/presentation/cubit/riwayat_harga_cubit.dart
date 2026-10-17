import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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

@injectable
class RiwayatHargaCubit extends Cubit<RiwayatHargaState> {
  final GetRiwayatHargaUseCase _getRiwayat;

  RiwayatHargaCubit(this._getRiwayat) : super(const RiwayatHargaState());

  Future<void> load(String jenisId) async {
    emit(const RiwayatHargaState());
    final result = await _getRiwayat.execute(jenisId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(RiwayatHargaState(
        status: RiwayatHargaStatus.failure,
        errorMessage: failure.displayMessage,
      )),
      (riwayat) => emit(RiwayatHargaState(
        status: RiwayatHargaStatus.loaded,
        riwayat: riwayat,
      )),
    );
  }
}
