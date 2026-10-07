import 'package:equatable/equatable.dart';

import '../../domain/entities/aktivitas_entity.dart';

enum AktivitasStatus { initial, loading, loaded, failure }

/// Type filtering is applied before pagination in the ledger endpoint.
enum AktivitasTipeFilter { semua, setoran, pencairan }

class RiwayatAktivitasState extends Equatable {
  final AktivitasStatus status;
  final List<ActivitasEntity> items;
  final String periode;
  final DateTime? dariTanggal;
  final DateTime? sampaiTanggal;
  final AktivitasTipeFilter tipeFilter;
  final String search;
  final String? errorMessage;
  final bool hasNext;
  final bool loadingMore;

  const RiwayatAktivitasState({
    this.status = AktivitasStatus.initial,
    this.items = const [],
    this.periode = 'bulan_ini',
    this.dariTanggal,
    this.sampaiTanggal,
    this.tipeFilter = AktivitasTipeFilter.semua,
    this.search = '',
    this.errorMessage,
    this.hasNext = false,
    this.loadingMore = false,
  });

  bool get isCustomPeriode => periode == 'custom';

  RiwayatAktivitasState copyWith({
    AktivitasStatus? status,
    List<ActivitasEntity>? items,
    String? periode,
    DateTime? dariTanggal,
    DateTime? sampaiTanggal,
    AktivitasTipeFilter? tipeFilter,
    String? search,
    String? errorMessage,
    bool? hasNext,
    bool? loadingMore,
  }) {
    return RiwayatAktivitasState(
      status: status ?? this.status,
      items: items ?? this.items,
      periode: periode ?? this.periode,
      dariTanggal: dariTanggal ?? this.dariTanggal,
      sampaiTanggal: sampaiTanggal ?? this.sampaiTanggal,
      tipeFilter: tipeFilter ?? this.tipeFilter,
      search: search ?? this.search,
      errorMessage: errorMessage,
      hasNext: hasNext ?? this.hasNext,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        periode,
        dariTanggal,
        sampaiTanggal,
        tipeFilter,
        search,
        errorMessage,
        hasNext,
        loadingMore,
      ];
}
