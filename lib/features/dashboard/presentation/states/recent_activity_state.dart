import 'package:equatable/equatable.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';

abstract class RecentActivityState extends Equatable {
  const RecentActivityState();

  @override
  List<Object?> get props => [];
}

class RecentActivityInitial extends RecentActivityState {}

class RecentActivityLoading extends RecentActivityState {}

class RecentActivityLoaded extends RecentActivityState {
  /// The latest activity — setoran and pencairan merged, newest first.
  /// Already trimmed to at most `RecentActivityNotifier.limit` entries (PIL-282).
  final List<ActivitasEntity> items;

  const RecentActivityLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class RecentActivityError extends RecentActivityState {
  final String message;

  const RecentActivityError(this.message);

  @override
  List<Object?> get props => [message];
}
