import 'package:equatable/equatable.dart';

abstract class TransaksiState extends Equatable {
  const TransaksiState();

  @override
  List<Object?> get props => [];
}

class TransaksiInitial extends TransaksiState {}

class TransaksiLoading extends TransaksiState {}

class TransaksiLoaded extends TransaksiState {
  final List<Map<String, dynamic>> transaksiList;
  final String activeFilter;
  final String searchQuery;

  const TransaksiLoaded({
    required this.transaksiList,
    this.activeFilter = 'Hari Ini',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [transaksiList, activeFilter, searchQuery];
}
