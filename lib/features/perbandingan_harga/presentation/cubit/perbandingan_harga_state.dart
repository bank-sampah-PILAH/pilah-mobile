import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/perbandingan_harga/domain/entities/perbandingan_harga_entities.dart';

abstract class PerbandinganHargaState extends Equatable {
  const PerbandinganHargaState();

  @override
  List<Object?> get props => [];
}

class PerbandinganHargaLoading extends PerbandinganHargaState {
  const PerbandinganHargaLoading();
}

class PerbandinganHargaError extends PerbandinganHargaState {
  final String message;

  const PerbandinganHargaError(this.message);

  @override
  List<Object?> get props => [message];
}

class PerbandinganHargaLoaded extends PerbandinganHargaState {
  final PerbandinganHargaEntity data;

  const PerbandinganHargaLoaded(this.data);

  @override
  List<Object?> get props => [data];
}
