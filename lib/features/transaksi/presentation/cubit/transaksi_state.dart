import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

abstract class TransaksiState extends Equatable {
  const TransaksiState();

  @override
  List<Object?> get props => [];
}

class TransaksiInitial extends TransaksiState {}

class TransaksiLoading extends TransaksiState {}

class TransaksiLoaded extends TransaksiState {
  final List<TransaksiGroupEntity> transaksiList;
  final String activeFilter;
  final String searchQuery;

  const TransaksiLoaded({
    required this.transaksiList,
    this.activeFilter = 'Bulan Ini',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [transaksiList, activeFilter, searchQuery];
}

class TransaksiError extends TransaksiState {
  final String message;

  const TransaksiError(this.message);

  @override
  List<Object?> get props => [message];
}
