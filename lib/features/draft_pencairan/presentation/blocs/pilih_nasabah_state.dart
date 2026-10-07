import 'package:equatable/equatable.dart';

import '../../domain/model/draft_pencairan.dart';

enum PilihStatus { loading, loaded, failure }

class PilihNasabahState extends Equatable {
  final PilihStatus status;

  /// What the current search and sort show.
  final List<Kandidat> kandidat;
  final String search;
  final KandidatUrutan urutan;
  final Set<String> selectedIds;

  /// Everyone seen so far, so a pick hidden by a later search still counts.
  final Map<String, Kandidat> known;
  final String? errorMessage;

  const PilihNasabahState({
    this.status = PilihStatus.loading,
    this.kandidat = const [],
    this.search = '',
    this.urutan = KandidatUrutan.namaAZ,
    this.selectedIds = const {},
    this.known = const {},
    this.errorMessage,
  });

  PilihNasabahState copyWith({
    PilihStatus? status,
    List<Kandidat>? kandidat,
    String? search,
    KandidatUrutan? urutan,
    Set<String>? selectedIds,
    Map<String, Kandidat>? known,
    String? Function()? errorMessage,
  }) =>
      PilihNasabahState(
        status: status ?? this.status,
        kandidat: kandidat ?? this.kandidat,
        search: search ?? this.search,
        urutan: urutan ?? this.urutan,
        selectedIds: selectedIds ?? this.selectedIds,
        known: known ?? this.known,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      );

  int get jumlahTerpilih => selectedIds.length;

  int get saldoTerpilih =>
      selectedIds.fold(0, (sum, id) => sum + (known[id]?.saldo ?? 0));

  /// The picked nasabah in name order, ready to start a draft from.
  List<Kandidat> get terpilih => [
        for (final id in selectedIds)
          if (known[id] != null) known[id]!,
      ]..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

  @override
  List<Object?> get props => [
        status,
        kandidat,
        search,
        urutan,
        selectedIds,
        known,
        errorMessage,
      ];
}
