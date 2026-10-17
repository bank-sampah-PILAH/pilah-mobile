import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';

class JadwalPageResult extends Equatable {
  final List<JadwalEntity> items;
  final int totalCount;
  final bool hasMore;

  const JadwalPageResult({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [items, totalCount, hasMore];
}
