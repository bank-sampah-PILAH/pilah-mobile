import 'package:equatable/equatable.dart';

abstract class NasabahState extends Equatable {
  const NasabahState();

  @override
  List<Object?> get props => [];
}

class NasabahInitial extends NasabahState {}

class NasabahLoading extends NasabahState {}

class NasabahLoaded extends NasabahState {
  final List<Map<String, dynamic>> nasabahList;
  final bool isActiveTab;
  final String searchQuery;

  const NasabahLoaded({
    required this.nasabahList,
    this.isActiveTab = true,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [nasabahList, isActiveTab, searchQuery];
}
