import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';

sealed class PengumumanState extends Equatable {
  const PengumumanState();

  @override
  List<Object?> get props => [];
}

class PengumumanInitial extends PengumumanState {
  const PengumumanInitial();
}

class PengumumanLoading extends PengumumanState {
  const PengumumanLoading();
}

class PengumumanLoaded extends PengumumanState {
  final List<PengumumanEntity> items;
  final bool isSaving;
  final bool isTransitioning;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadingMoreError;
  final int totalCount;
  final String statusFilter;

  const PengumumanLoaded(
    this.items, {
    this.isSaving = false,
    this.isTransitioning = false,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadingMoreError,
    this.totalCount = 0,
    this.statusFilter = '',
  });

  PengumumanLoaded copyWith({
    List<PengumumanEntity>? items,
    bool? isSaving,
    bool? isTransitioning,
    bool? isLoading,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadingMoreError,
    bool clearLoadingMoreError = false,
    int? totalCount,
    String? statusFilter,
  }) =>
      PengumumanLoaded(
        items ?? this.items,
        isSaving: isSaving ?? this.isSaving,
        isTransitioning: isTransitioning ?? this.isTransitioning,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadingMoreError: clearLoadingMoreError
            ? null
            : loadingMoreError ?? this.loadingMoreError,
        totalCount: totalCount ?? this.totalCount,
        statusFilter: statusFilter ?? this.statusFilter,
      );

  @override
  List<Object?> get props => [
        items,
        isSaving,
        isTransitioning,
        isLoading,
        hasMore,
        isLoadingMore,
        loadingMoreError,
        totalCount,
        statusFilter,
      ];
}

class PengumumanError extends PengumumanState {
  final String message;

  const PengumumanError(this.message);

  @override
  List<Object?> get props => [message];
}
