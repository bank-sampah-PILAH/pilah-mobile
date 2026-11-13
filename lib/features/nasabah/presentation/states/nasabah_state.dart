import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_urutan.dart';

abstract class NasabahState extends Equatable {
  const NasabahState();

  @override
  List<Object?> get props => [];
}

class NasabahInitial extends NasabahState {}

class NasabahLoading extends NasabahState {
  final bool? isActiveTab;

  const NasabahLoading({this.isActiveTab = true});

  @override
  List<Object?> get props => [isActiveTab];
}

class NasabahLoaded extends NasabahState {
  final List<NasabahEntity> nasabahList;

  /// `true` = aktif, `false` = tidak aktif, `null` = menunggu.
  final bool? isActiveTab;
  final String searchQuery;
  final NasabahUrutan urutan;

  /// Masih ada halaman berikutnya di server (PIL-214).
  final bool hasMore;

  /// Halaman berikutnya sedang diambil; dipakai untuk pemuat di ujung daftar.
  final bool isLoadingMore;

  /// Halaman pertama sedang dimuat ulang sementara baris lama tetap terlihat.
  final bool isReloading;

  /// Jumlah seluruh nasabah yang cocok di server, bukan yang sudah dimuat.
  final int totalCount;
  final int currentPage;
  final int pageSize;

  const NasabahLoaded({
    required this.nasabahList,
    this.isActiveTab = true,
    this.searchQuery = '',
    this.urutan = NasabahUrutan.nomor,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isReloading = false,
    this.totalCount = 0,
    this.currentPage = 1,
    this.pageSize = 20,
  });

  bool get isMenungguTab => isActiveTab == null;

  @override
  List<Object?> get props => [
        nasabahList,
        isActiveTab,
        searchQuery,
        urutan,
        hasMore,
        isLoadingMore,
        isReloading,
        totalCount,
        currentPage,
        pageSize,
      ];
}

class NasabahError extends NasabahState {
  final String message;

  const NasabahError(this.message);

  @override
  List<Object?> get props => [message];
}
