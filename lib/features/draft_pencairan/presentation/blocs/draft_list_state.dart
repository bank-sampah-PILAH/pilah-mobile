import 'package:equatable/equatable.dart';

import '../../domain/model/draft_pencairan.dart';
import '../widgets/draft_format.dart';

enum DraftListStatus { loading, loaded, failure }

enum DraftSortField {
  tanggal('Tanggal'),
  dibayar('Total dibayar'),
  nama('Nama');

  final String label;

  const DraftSortField(this.label);
}

/// A field and a direction, as in the nasabah list of a draft: names go A-Z
/// first and the rest biggest or newest first, and choosing the same field
/// again flips it. Only the date order is grouped under date headings; under
/// the others the dates would jump around.
class DraftSort extends Equatable {
  final DraftSortField field;
  final bool ascending;

  const DraftSort(this.field, this.ascending);

  const DraftSort.awal() : this(DraftSortField.tanggal, false);

  bool get perTanggal => field == DraftSortField.tanggal;

  DraftSort pilih(DraftSortField pilihan) => pilihan == field
      ? DraftSort(field, !ascending)
      : DraftSort(pilihan, pilihan == DraftSortField.nama);

  @override
  List<Object?> get props => [field, ascending];
}

class DraftListState extends Equatable {
  final DraftListStatus status;
  final List<DraftRingkasan> drafts;

  /// Null shows every status.
  final DraftStatus? filter;
  final String? errorMessage;

  /// What was typed in the search field; matched against name, maker and date.
  final String query;
  final DraftSort urutan;

  const DraftListState({
    this.status = DraftListStatus.loading,
    this.drafts = const [],
    this.filter,
    this.errorMessage,
    this.query = '',
    this.urutan = const DraftSort.awal(),
  });

  /// Drafts matching the search, whatever their status.
  List<DraftRingkasan> get _cocok {
    final kata = query.trim().toLowerCase();
    if (kata.isEmpty) return drafts;
    return drafts.where((draft) {
      final teks = '${draft.nama} ${draft.dibuatOlehNama} '
              '${waktu(draft.createdAt)}'
          .toLowerCase();
      return teks.contains(kata);
    }).toList();
  }

  /// How many drafts of [status] match the search; every status for null.
  int jumlah(DraftStatus? status) => status == null
      ? _cocok.length
      : _cocok.where((draft) => draft.status == status).length;

  /// What the list shows: searched, narrowed to the chosen status, ordered.
  List<DraftRingkasan> get tampil {
    final hasil = _cocok
        .where((draft) => filter == null || draft.status == filter)
        .toList();
    final awal = DateTime.fromMillisecondsSinceEpoch(0);
    int waktuDari(DraftRingkasan draft) =>
        (draft.createdAt ?? awal).millisecondsSinceEpoch;
    int banding(DraftRingkasan a, DraftRingkasan b) {
      final hasilBanding = switch (urutan.field) {
        DraftSortField.tanggal => waktuDari(a).compareTo(waktuDari(b)),
        DraftSortField.dibayar => a.totalDibayar.compareTo(b.totalDibayar),
        DraftSortField.nama =>
          a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
      };
      final arah = urutan.ascending ? hasilBanding : -hasilBanding;
      return arah != 0 ? arah : a.id.compareTo(b.id);
    }

    hasil.sort(banding);
    return hasil;
  }

  DraftListState copyWith({
    DraftListStatus? status,
    List<DraftRingkasan>? drafts,
    DraftStatus? Function()? filter,
    String? Function()? errorMessage,
    String? query,
    DraftSort? urutan,
  }) =>
      DraftListState(
        status: status ?? this.status,
        drafts: drafts ?? this.drafts,
        filter: filter != null ? filter() : this.filter,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
        query: query ?? this.query,
        urutan: urutan ?? this.urutan,
      );

  @override
  List<Object?> get props =>
      [status, drafts, filter, errorMessage, query, urutan];
}
