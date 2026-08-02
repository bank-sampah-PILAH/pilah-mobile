import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/transaksi_entity.dart';

abstract class RecentActivityState extends Equatable {
  const RecentActivityState();

  @override
  List<Object?> get props => [];
}

class RecentActivityInitial extends RecentActivityState {}

class RecentActivityLoading extends RecentActivityState {}

class RecentActivityLoaded extends RecentActivityState {
  /// The latest transactions, still grouped by day so each one can be labelled
  /// ("Hari ini", "Kemarin", …). Already trimmed to at most
  /// `RecentActivityCubit.limit` transactions in total.
  final List<TransaksiGroupEntity> groups;

  const RecentActivityLoaded(this.groups);

  @override
  List<Object?> get props => [groups];
}

class RecentActivityError extends RecentActivityState {
  final String message;

  const RecentActivityError(this.message);

  @override
  List<Object?> get props => [message];
}
