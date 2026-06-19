import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';

abstract class HargaState extends Equatable {
  const HargaState();

  @override
  List<Object?> get props => [];
}

class HargaInitial extends HargaState {}

class HargaLoading extends HargaState {}

class HargaLoaded extends HargaState {
  final List<HargaEntity> jenisSampahList;
  final bool isActiveTab;
  final String searchQuery;

  const HargaLoaded({
    required this.jenisSampahList,
    this.isActiveTab = true,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [jenisSampahList, isActiveTab, searchQuery];
}

class HargaError extends HargaState {
  final String message;

  const HargaError(this.message);

  @override
  List<Object?> get props => [message];
}
