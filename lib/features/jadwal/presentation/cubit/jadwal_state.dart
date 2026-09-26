import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';

sealed class JadwalState extends Equatable {
  const JadwalState();

  @override
  List<Object?> get props => [];
}

class JadwalInitial extends JadwalState {
  const JadwalInitial();
}

class JadwalLoading extends JadwalState {
  const JadwalLoading();
}

class JadwalLoaded extends JadwalState {
  final List<JadwalEntity> items;
  final bool isSaving;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadingMoreError;
  final int totalCount;
  final Set<DateTime> scheduledDates;

  const JadwalLoaded(
    this.items, {
    this.isSaving = false,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadingMoreError,
    this.totalCount = 0,
    this.scheduledDates = const {},
  });

  JadwalLoaded copyWith({
    List<JadwalEntity>? items,
    bool? isSaving,
    bool? isLoading,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadingMoreError,
    bool clearLoadingMoreError = false,
    int? totalCount,
    Set<DateTime>? scheduledDates,
  }) =>
      JadwalLoaded(
        items ?? this.items,
        isSaving: isSaving ?? this.isSaving,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: clearLoadingMoreError
            ? null
            : loadingMoreError ?? this.loadingMoreError,
        totalCount: totalCount ?? this.totalCount,
        scheduledDates: scheduledDates ?? this.scheduledDates,
      );

  @override
  List<Object?> get props => [
        items,
        isSaving,
        isLoading,
        hasMore,
        isLoadingMore,
        loadingMoreError,
        totalCount,
        scheduledDates,
      ];
}

class JadwalError extends JadwalState {
  final String message;

  const JadwalError(this.message);

  @override
  List<Object?> get props => [message];
}
