import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/model/revisi_pencairan.dart';
import '../../domain/use_cases/pencairan_use_cases.dart';

enum RevisiStatus { loading, loaded, failure }

class RevisiPencairanState extends Equatable {
  final RevisiStatus status;
  final RiwayatRevisiPencairan? riwayat;
  final String? errorMessage;

  const RevisiPencairanState({
    this.status = RevisiStatus.loading,
    this.riwayat,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, riwayat, errorMessage];
}

@Injectable()
class RevisiPencairanCubit extends Cubit<RevisiPencairanState> {
  final PencairanUseCases _useCases;

  RevisiPencairanCubit(this._useCases) : super(const RevisiPencairanState());

  Future<void> load(String pencairanId) async {
    emit(const RevisiPencairanState());
    final result = await _useCases.getRevisi(pencairanId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(RevisiPencairanState(
        status: RevisiStatus.failure,
        errorMessage: failure.displayMessage,
      )),
      (riwayat) => emit(RevisiPencairanState(
        status: RevisiStatus.loaded,
        riwayat: riwayat,
      )),
    );
  }
}
