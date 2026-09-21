import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';

@lazySingleton
class JadwalCubit extends Cubit<JadwalState> {
  final JadwalRepository repository;

  JadwalCubit(this.repository) : super(const JadwalInitial());

  List<JadwalEntity> get _items =>
      state is JadwalLoaded ? (state as JadwalLoaded).items : const [];

  Future<void> loadJadwal({bool silent = false}) async {
    if (!silent || state is! JadwalLoaded) emit(const JadwalLoading());
    final result = await repository.getJadwal();
    result.fold(
      (failure) => emit(JadwalError(failure.displayMessage)),
      (items) => emit(JadwalLoaded(items)),
    );
  }

  Future<NetworkException?> saveJadwal(JadwalEntity jadwal) async {
    final currentItems = _items;
    emit(JadwalLoaded(currentItems, isSaving: true));
    final result = jadwal.id.isEmpty
        ? await repository.createJadwal(jadwal)
        : await repository.updateJadwal(jadwal);
    return result.fold(
      (failure) {
        emit(JadwalLoaded(currentItems));
        return failure;
      },
      (_) async {
        await loadJadwal(silent: true);
        return null;
      },
    );
  }

  Future<NetworkException?> changeStatus(String id, String action) async {
    final result = await repository.transition(id, action);
    return result.fold(
      (failure) => failure,
      (_) async {
        await loadJadwal(silent: true);
        return null;
      },
    );
  }

  void reset() => emit(const JadwalInitial());
}
