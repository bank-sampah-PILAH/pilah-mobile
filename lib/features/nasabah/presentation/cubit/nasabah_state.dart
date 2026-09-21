import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';

abstract class NasabahState extends Equatable {
  const NasabahState();

  @override
  List<Object?> get props => [];
}

class NasabahInitial extends NasabahState {}

class NasabahLoading extends NasabahState {}

class NasabahLoaded extends NasabahState {
  final List<NasabahEntity> nasabahList;

  /// `true` = aktif, `false` = tidak aktif, `null` = menunggu.
  final bool? isActiveTab;
  final String searchQuery;

  const NasabahLoaded({
    required this.nasabahList,
    this.isActiveTab = true,
    this.searchQuery = '',
  });

  bool get isMenungguTab => isActiveTab == null;

  @override
  List<Object?> get props => [nasabahList, isActiveTab, searchQuery];
}

class NasabahError extends NasabahState {
  final String message;

  const NasabahError(this.message);

  @override
  List<Object?> get props => [message];
}
