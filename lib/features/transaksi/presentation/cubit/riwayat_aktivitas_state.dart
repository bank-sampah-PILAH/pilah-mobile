import 'package:equatable/equatable.dart';

import '../../domain/entities/aktivitas_entity.dart';
import '../../domain/entities/aktivitas_summary.dart';

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
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int? retryPage;
  final AktivitasSummary? summary;

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
    this.currentPage = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.retryPage,
    this.summary,
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
    int? currentPage,
    int? pageSize,
    int? totalCount,
    int? retryPage,
    AktivitasSummary? summary,
    bool clearSummary = false,
    bool clearRetryPage = false,
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
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      retryPage: clearRetryPage ? null : retryPage ?? this.retryPage,
      summary: clearSummary ? null : summary ?? this.summary,
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
        currentPage,
        pageSize,
        totalCount,
        retryPage,
        summary,
      ];
}
