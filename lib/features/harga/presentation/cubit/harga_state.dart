import 'package:equatable/equatable.dart';

abstract class HargaState extends Equatable {
  const HargaState();

  @override
  List<Object?> get props => [];
}

class HargaInitial extends HargaState {}

class HargaLoading extends HargaState {}

class HargaLoaded extends HargaState {
  final List<Map<String, dynamic>> jenisSampahList;
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
