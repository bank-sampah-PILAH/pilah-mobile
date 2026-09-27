import 'package:equatable/equatable.dart';

/// The periods offered on the riwayat screen. [apiValue] is the backend
/// `periode`; `null` for [semua] because the pencairan list returns the whole
/// history when `periode` is omitted.
enum RiwayatPeriode {
  semua('Semua', null),
  bulanIni('Bulan Ini', 'bulan_ini'),
  bulanLalu('Bulan Lalu', 'bulan_lalu');

  const RiwayatPeriode(this.label, this.apiValue);

  final String label;
  final String? apiValue;
}

class RiwayatPencairanFilter extends Equatable {
  final RiwayatPeriode periode;
  final String? nasabahId;
  final String search;

  /// Caps the result to the newest [limit] records and tells the data source
  /// to stop after the first page instead of walking the whole history — the
  /// backend already returns pencairan newest-first (`Pencairan.Meta.ordering
  /// = ["-tanggal"]`), so a single page already holds the answer. Null means
  /// "the whole matching history", the pre-existing behavior every riwayat
  /// screen still relies on.
  final int? limit;

  const RiwayatPencairanFilter({
    this.periode = RiwayatPeriode.semua,
    this.nasabahId,
    this.search = '',
    this.limit,
  });

  RiwayatPencairanFilter copyWith({RiwayatPeriode? periode, String? search}) {
    return RiwayatPencairanFilter(
      periode: periode ?? this.periode,
      nasabahId: nasabahId,
      search: search ?? this.search,
      limit: limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final search = this.search.trim();
    return {
      if (periode.apiValue != null) 'periode': periode.apiValue,
      if (nasabahId != null) 'nasabah_id': nasabahId,
      if (search.isNotEmpty) 'search': search,
      'page_size': limit ?? 100,
    };
  }

  @override
  List<Object?> get props => [periode, nasabahId, search, limit];
}
