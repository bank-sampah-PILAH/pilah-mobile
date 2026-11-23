import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';

abstract class SuperadminState extends Equatable {
  const SuperadminState();

  @override
  List<Object?> get props => [];
}

class SuperadminInitial extends SuperadminState {}

class SuperadminLoading extends SuperadminState {}

class SuperadminLoaded extends SuperadminState {
  final List<BankSampahEntity> banks;
  final String status;

  const SuperadminLoaded({required this.banks, required this.status});

  @override
  List<Object?> get props => [banks, status];
}

class SuperadminError extends SuperadminState {
  final String message;

  const SuperadminError(this.message);

  @override
  List<Object?> get props => [message];
}
