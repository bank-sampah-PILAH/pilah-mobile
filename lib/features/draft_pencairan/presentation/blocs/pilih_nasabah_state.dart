import 'package:equatable/equatable.dart';

import '../../domain/model/draft_pencairan.dart';

enum PilihStatus { loading, loaded, failure }

/// Which of the listed nasabah to show.
enum PilihFilter {
  semua('Semua'),
  terpilih('Terpilih'),
  belumDipilih('Belum dipilih'),
  saldoKosong('Saldo kosong');

  final String label;

  const PilihFilter(this.label);
}

/// How much of what is shown is picked, for the tri-state checkbox.
enum PilihanTampil { tidakAda, sebagian, semua }

class PilihNasabahState extends Equatable {
  final PilihStatus status;

  /// What the current search and sort show.
  final List<Kandidat> kandidat;
  final String search;
  final KandidatUrutan urutan;
  final Set<String> selectedIds;
  final PilihFilter filter;

  /// Show only nasabah with at least this much saldo; 0 for no limit.
  final int saldoMin;

  /// Everyone seen so far, so a pick hidden by a later search still counts.
  final Map<String, Kandidat> known;
  final String? errorMessage;

  const PilihNasabahState({
    this.status = PilihStatus.loading,
    this.kandidat = const [],
    this.search = '',
    this.urutan = KandidatUrutan.namaAZ,
    this.selectedIds = const {},
    this.filter = PilihFilter.semua,
    this.saldoMin = 0,
    this.known = const {},
    this.errorMessage,
  });

  PilihNasabahState copyWith({
    PilihStatus? status,
    List<Kandidat>? kandidat,
    String? search,
    KandidatUrutan? urutan,
    Set<String>? selectedIds,
    PilihFilter? filter,
    int? saldoMin,
    Map<String, Kandidat>? known,
    String? Function()? errorMessage,
  }) =>
      PilihNasabahState(
        status: status ?? this.status,
        kandidat: kandidat ?? this.kandidat,
        search: search ?? this.search,
        urutan: urutan ?? this.urutan,
        selectedIds: selectedIds ?? this.selectedIds,
        filter: filter ?? this.filter,
        saldoMin: saldoMin ?? this.saldoMin,
        known: known ?? this.known,
        errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      );

  /// What the minimum saldo leaves of the list the server sent.
  List<Kandidat> get _melewatiSaldo => saldoMin > 0
      ? kandidat.where((k) => k.saldo >= saldoMin).toList()
      : kandidat;

  bool _cocok(Kandidat k, PilihFilter f) => switch (f) {
        PilihFilter.semua => true,
        PilihFilter.terpilih => selectedIds.contains(k.id),
        PilihFilter.belumDipilih => !selectedIds.contains(k.id),
        PilihFilter.saldoKosong => k.kosong,
      };

  /// What the list shows: the server's list, the minimum saldo and the filter.
  List<Kandidat> get tampil =>
      _melewatiSaldo.where((k) => _cocok(k, filter)).toList();

  /// How many nasabah [f] would show, for the count on its chip.
  int jumlah(PilihFilter f) => _melewatiSaldo.where((k) => _cocok(k, f)).length;

  /// Of what is shown, those who can be picked at all.
  List<Kandidat> get dapatDipilih => tampil.where((k) => !k.kosong).toList();

  PilihanTampil get pilihanTampil {
    final dapat = dapatDipilih;
    final dipilih = dapat.where((k) => selectedIds.contains(k.id)).length;
    if (dipilih == 0) return PilihanTampil.tidakAda;
    return dipilih == dapat.length
        ? PilihanTampil.semua
        : PilihanTampil.sebagian;
  }

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
        filter,
        saldoMin,
        known,
        errorMessage,
      ];
}
