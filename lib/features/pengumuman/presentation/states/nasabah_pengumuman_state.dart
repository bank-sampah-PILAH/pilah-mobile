import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';

enum NasabahPengumumanStatus { initial, loading, loaded, failure }

class NasabahPengumumanState extends Equatable {
  final NasabahPengumumanStatus status;
  final List<PengumumanEntity> items;
  final bool hasNext;
  final int page;
  final bool isLoadingMore;
  final String error;

  const NasabahPengumumanState({
    this.status = NasabahPengumumanStatus.initial,
    this.items = const [],
    this.hasNext = false,
    this.page = 1,
    this.isLoadingMore = false,
    this.error = '',
  });

  NasabahPengumumanState copyWith({
    NasabahPengumumanStatus? status,
    List<PengumumanEntity>? items,
    bool? hasNext,
    int? page,
    bool? isLoadingMore,
    String? error,
  }) =>
      NasabahPengumumanState(
        status: status ?? this.status,
        items: items ?? this.items,
        hasNext: hasNext ?? this.hasNext,
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [status, items, hasNext, page, isLoadingMore, error];
}
