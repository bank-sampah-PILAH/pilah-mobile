import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/revisi_pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/services/di.dart';

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

final revisiPencairanProvider =
    NotifierProvider.autoDispose<RevisiPencairanNotifier, RevisiPencairanState>(
  () => RevisiPencairanNotifier(di<PencairanUseCases>()),
);

class RevisiPencairanNotifier extends Notifier<RevisiPencairanState> {
  RevisiPencairanNotifier(this._useCases);

  final PencairanUseCases _useCases;
  int _loadVersion = 0;

  @override
  RevisiPencairanState build() => const RevisiPencairanState();

  Future<void> load(String pencairanId) async {
    final version = ++_loadVersion;
    state = const RevisiPencairanState();
    final result = await _useCases.getRevisi(pencairanId);
    if (!ref.mounted || version != _loadVersion) return;
    result.fold(
      (failure) => state = RevisiPencairanState(
        status: RevisiStatus.failure,
        errorMessage: failure.displayMessage,
      ),
      (riwayat) => state = RevisiPencairanState(
        status: RevisiStatus.loaded,
        riwayat: riwayat,
      ),
    );
  }
}
