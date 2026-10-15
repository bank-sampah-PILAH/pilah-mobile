import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/onboarding_entities.dart';

abstract class CariBankState extends Equatable {
  const CariBankState();

  @override
  List<Object?> get props => [];
}

class CariBankInitial extends CariBankState {
  const CariBankInitial();
}

/// Halaman pertama sedang dimuat — daftar belum punya apa pun untuk tampil.
class CariBankLoading extends CariBankState {
  const CariBankLoading();
}

class CariBankError extends CariBankState {
  final String message;

  const CariBankError(this.message);

  @override
  List<Object?> get props => [message];
}

class CariBankLoaded extends CariBankState {
  final List<BankSampahDirectoryEntity> items;

  /// Masih ada halaman berikutnya di server (envelope `next`).
  final bool hasMore;

  /// Halaman berikutnya sedang diambil; dipakai untuk pemuat di ujung daftar.
  final bool isLoadingMore;

  /// Jumlah seluruh bank yang cocok di server, bukan yang sudah dimuat.
  final int totalCount;

  /// Kata kunci yang sedang aktif (PIL-308), untuk label hasil kosong.
  final String searchQuery;
  final String kotaFilter;

  const CariBankLoaded({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.totalCount,
    required this.searchQuery,
    required this.kotaFilter,
  });

  @override
  List<Object?> get props =>
      [items, hasMore, isLoadingMore, totalCount, searchQuery, kotaFilter];
}
