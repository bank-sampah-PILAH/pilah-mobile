import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/models/jenis_sampah_query.dart';

abstract class HargaState extends Equatable {
  const HargaState();

  @override
  List<Object?> get props => [];
}

class HargaInitial extends HargaState {}

class HargaLoading extends HargaState {}

class HargaLoaded extends HargaState {
  final List<HargaEntity> jenisSampahList;
  final bool isActiveTab;

  /// Cari, kategori, dan urutan yang sedang berlaku pada [jenisSampahList].
  final JenisSampahQuery query;

  /// Kategori yang ada di tab ini, untuk chip filter.
  final List<String> kategori;

  const HargaLoaded({
    required this.jenisSampahList,
    this.isActiveTab = true,
    this.query = const JenisSampahQuery(),
    this.kategori = const [],
  });

  String get searchQuery => query.search;

  @override
  List<Object?> get props => [jenisSampahList, isActiveTab, query, kategori];
}

class HargaError extends HargaState {
  final String message;

  const HargaError(this.message);

  @override
  List<Object?> get props => [message];
}
