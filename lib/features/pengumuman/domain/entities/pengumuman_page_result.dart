import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';

class PengumumanPageResult extends Equatable {
  final List<PengumumanEntity> items;
  final int totalCount;
  final bool hasMore;

  const PengumumanPageResult({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, totalCount, hasMore];
}
