import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

abstract class NasabahApprovalState extends Equatable {
  const NasabahApprovalState();

  @override
  List<Object?> get props => [];
}

class NasabahApprovalInitial extends NasabahApprovalState {
  const NasabahApprovalInitial();
}

class NasabahApprovalLoading extends NasabahApprovalState {
  const NasabahApprovalLoading();
}

class NasabahApprovalLoaded extends NasabahApprovalState {
  final List<NasabahMembershipEntity> memberships;

  const NasabahApprovalLoaded(this.memberships);

  @override
  List<Object?> get props => [memberships];
}

class NasabahApprovalError extends NasabahApprovalState {
  final String message;

  const NasabahApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}
