import 'package:equatable/equatable.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';

enum DraftStatus {
  draft('Draft'),
  dikonfirmasi('Dikonfirmasi'),
  dibatalkan('Dibatalkan');

  const DraftStatus(this.label);

  final String label;

  /// Only a draft can still be edited, confirmed or cancelled.
  bool get terkunci => this != draft;

  static DraftStatus fromApi(String? value) => DraftStatus.values
      .firstWhere((s) => s.name == value, orElse: () => DraftStatus.draft);
}

enum PotonganJenis {
  persen('Persen'),
  rupiah('Nominal');

  const PotonganJenis(this.label);

  final String label;

  static PotonganJenis? fromApi(String? value) {
    for (final jenis in PotonganJenis.values) {
      if (jenis.name == value) return jenis;
    }
    return null;
  }
}

/// A potongan the pengurus chose: a percentage of the nominal, or fixed rupiah.
class Potongan extends Equatable {
  final PotonganJenis jenis;
  final num nilai;

  const Potongan(this.jenis, this.nilai);

  static const nol = Potongan(PotonganJenis.persen, 0);

  /// The potongan on [nominal], rounded down to whole rupiah per item, exactly as
  /// the backend does, so the screen total never disagrees with what is saved.
  int hitung(int nominal) {
    switch (jenis) {
      case PotonganJenis.persen:
        // Percent in hundredths (2.5% -> 250) keeps the arithmetic in integers.
        return (nominal * (nilai * 100).round()) ~/ 10000;
      case PotonganJenis.rupiah:
        return nilai.floor();
    }
  }

  /// Whole numbers are sent as integers, so 10 stays `10` rather than `10.0`.
  num get nilaiJson => nilai == nilai.truncate() ? nilai.truncate() : nilai;

  @override
  List<Object?> get props => [jenis, nilai];
}

enum KandidatUrutan {
  namaAZ('nama', 'Nama A-Z'),
  namaZA('-nama', 'Nama Z-A'),
  saldoTerkecil('saldo', 'Saldo terkecil'),
  saldoTerbesar('-saldo', 'Saldo terbesar');

  const KandidatUrutan(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// A nasabah who can still be paid out: active, approved, with saldo.
class Kandidat extends Equatable {
  final String id;
  final String kode;
  final String nama;
  final int saldo;

  const Kandidat({
    required this.id,
    required this.kode,
    required this.nama,
    required this.saldo,
  });

  @override
  List<Object?> get props => [id, kode, nama, saldo];
}

class DraftItem extends Equatable {
  final String id;
  final String nasabahId;
  final String nasabahNama;
  final int nominal;
  final MetodePencairan metode;

  /// The item's own potongan; null means it follows the draft default.
  final Potongan? potongan;

  /// The potongan that applies after the default is resolved, in rupiah.
  final int potonganEfektif;
  final int dibayar;

  /// The nasabah's saldo right now; the nominal was fixed when it was drafted.
  final int saldoSaatIni;

  const DraftItem({
    this.id = '',
    required this.nasabahId,
    required this.nasabahNama,
    required this.nominal,
    required this.metode,
    this.potongan,
    required this.potonganEfektif,
    required this.dibayar,
    required this.saldoSaatIni,
  });

  @override
  List<Object?> get props => [
        id,
        nasabahId,
        nasabahNama,
        nominal,
        metode,
        potongan,
        potonganEfektif,
        dibayar,
        saldoSaatIni,
      ];
}

class DraftPencairan extends Equatable {
  final String id;
  final String nama;
  final DraftStatus status;
  final Potongan potonganDefault;
  final String dibuatOlehNama;
  final String diubahOlehNama;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DraftItem> items;
  final int totalNominal;
  final int totalPotongan;
  final int totalDibayar;

  const DraftPencairan({
    required this.id,
    required this.nama,
    required this.status,
    required this.potonganDefault,
    this.dibuatOlehNama = '',
    this.diubahOlehNama = '',
    this.createdAt,
    this.updatedAt,
    required this.items,
    required this.totalNominal,
    required this.totalPotongan,
    required this.totalDibayar,
  });

  @override
  List<Object?> get props => [
        id,
        nama,
        status,
        potonganDefault,
        dibuatOlehNama,
        diubahOlehNama,
        createdAt,
        updatedAt,
        items,
        totalNominal,
        totalPotongan,
        totalDibayar,
      ];
}

/// One row of the draft list: no items, just enough to find and resume a draft.
class DraftRingkasan extends Equatable {
  final String id;
  final String nama;
  final DraftStatus status;
  final String dibuatOlehNama;
  final String diubahOlehNama;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int jumlahItem;
  final int totalNominal;
  final int totalPotongan;
  final int totalDibayar;

  const DraftRingkasan({
    required this.id,
    required this.nama,
    required this.status,
    this.dibuatOlehNama = '',
    this.diubahOlehNama = '',
    this.createdAt,
    this.updatedAt,
    required this.jumlahItem,
    required this.totalNominal,
    required this.totalPotongan,
    required this.totalDibayar,
  });

  @override
  List<Object?> get props => [
        id,
        nama,
        status,
        dibuatOlehNama,
        diubahOlehNama,
        createdAt,
        updatedAt,
        jumlahItem,
        totalNominal,
        totalPotongan,
        totalDibayar,
      ];
}

class DraftItemInput extends Equatable {
  final String nasabahId;
  final int nominal;
  final MetodePencairan metode;

  /// Null clears the item's own potongan so it follows the draft default.
  final Potongan? potongan;

  const DraftItemInput({
    required this.nasabahId,
    required this.nominal,
    required this.metode,
    this.potongan,
  });

  @override
  List<Object?> get props => [nasabahId, nominal, metode, potongan];
}

/// What the editor sends, for a new draft and for an edit alike: the whole
/// desired state, since the backend replaces the item list.
class DraftInput extends Equatable {
  final String? nama;
  final Potongan potonganDefault;
  final List<DraftItemInput> items;

  const DraftInput({
    this.nama,
    required this.potonganDefault,
    required this.items,
  });

  @override
  List<Object?> get props => [nama, potonganDefault, items];
}
