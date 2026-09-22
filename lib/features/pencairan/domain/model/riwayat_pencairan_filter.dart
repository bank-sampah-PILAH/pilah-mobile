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

  const RiwayatPencairanFilter({
    this.periode = RiwayatPeriode.semua,
    this.nasabahId,
    this.search = '',
  });

  RiwayatPencairanFilter copyWith({RiwayatPeriode? periode, String? search}) {
    return RiwayatPencairanFilter(
      periode: periode ?? this.periode,
      nasabahId: nasabahId,
      search: search ?? this.search,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final search = this.search.trim();
    return {
      if (periode.apiValue != null) 'periode': periode.apiValue,
      if (nasabahId != null) 'nasabah_id': nasabahId,
      if (search.isNotEmpty) 'search': search,
      'page_size': 100,
    };
  }

  @override
  List<Object?> get props => [periode, nasabahId, search];
}
