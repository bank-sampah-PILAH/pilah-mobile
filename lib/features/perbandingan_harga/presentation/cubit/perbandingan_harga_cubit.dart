import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/core/client/api_call.dart';
import 'package:pilah_mobile/features/perbandingan_harga/data/datasources/perbandingan_harga_remote_data_source.dart';
import 'package:pilah_mobile/features/perbandingan_harga/domain/entities/perbandingan_harga_entities.dart';
import 'package:pilah_mobile/features/perbandingan_harga/presentation/cubit/perbandingan_harga_state.dart';

/// Loads one price comparison (PIL-309): a jenis anchor plus the banks to
/// compare. No pagination, no filters — one call, one result.
@lazySingleton
class PerbandinganHargaCubit extends Cubit<PerbandinganHargaState> {
  final PerbandinganHargaRemoteDataSource _dataSource;

  PerbandinganHargaCubit(this._dataSource)
      : super(const PerbandinganHargaLoading());

  Future<void> muat({
    required String jenisSampahId,
    required List<String> bankIds,
  }) async {
    if (bankIds.isEmpty) return;
    emit(const PerbandinganHargaLoading());
    final either = await apiCall<PerbandinganHargaEntity>(
      func: _dataSource.compare(
        jenisSampahId: jenisSampahId,
        bankIds: bankIds,
      ),
      mapper: (value) => value as PerbandinganHargaEntity,
    );
    if (isClosed) return;
    either.fold(
      (error) => emit(PerbandinganHargaError(error.displayMessage)),
      (data) => emit(PerbandinganHargaLoaded(data)),
    );
  }
}
