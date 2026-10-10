import 'dart:typed_data';

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

/// How a general jumlah is given: a share of each saldo, or a fixed rupiah.
enum JumlahJenis {
  persen('Persen'),
  rupiah('Nominal');

  const JumlahJenis(this.label);

  final String label;

  static JumlahJenis? fromApi(String? value) {
    for (final jenis in values) {
      if (jenis.name == value) return jenis;
    }
    // The API calls the fixed rupiah kind 'rupiah', as for potongan.
    return null;
  }
}

/// A way to set everyone's pencairan at once: the same share of each saldo, or
/// the same rupiah for all. The whole saldo is simply 100 percent.
class JumlahUmum extends Equatable {
  final JumlahJenis jenis;
  final num nilai;

  const JumlahUmum(this.jenis, this.nilai);

  static const penuh = JumlahUmum(JumlahJenis.persen, 100);

  /// Whole numbers are sent as integers, so 50 stays `50` rather than `50.0`.
  num get nilaiJson => nilai == nilai.truncate() ? nilai.truncate() : nilai;

  /// Whether it can be applied: a share up to 100, or a rupiah above zero.
  bool get valid {
    switch (jenis) {
      case JumlahJenis.persen:
        return nilai > 0 && nilai <= 100;
      case JumlahJenis.rupiah:
        return nilai >= 1;
    }
  }

  /// What a nasabah with [saldo] is paid, in whole rupiah rounded down. A fixed
  /// rupiah is a ceiling: someone with less is paid their whole saldo.
  int hitung(int saldo) {
    switch (jenis) {
      case JumlahJenis.persen:
        // Hundredths of a percent keep the arithmetic in integers.
        return (saldo * (nilai * 100).round()) ~/ 10000;
      case JumlahJenis.rupiah:
        final tetap = nilai.floor();
        return tetap < saldo ? tetap : saldo;
    }
  }

  @override
  List<Object?> get props => [jenis, nilai];
}

/// What the picker can be ordered by. The direction is separate, so one
/// button can carry both, as in the lists elsewhere in pencairan.
enum KandidatSortField {
  nama('Nama'),
  saldo('Saldo');

  final String label;

  const KandidatSortField(this.label);
}

enum KandidatUrutan {
  namaAZ('nama', KandidatSortField.nama, true),
  namaZA('-nama', KandidatSortField.nama, false),
  saldoTerkecil('saldo', KandidatSortField.saldo, true),
  saldoTerbesar('-saldo', KandidatSortField.saldo, false);

  const KandidatUrutan(this.apiValue, this.field, this.ascending);

  final String apiValue;
  final KandidatSortField field;
  final bool ascending;

  /// The order after choosing [pilihan]: the same field again flips the
  /// direction; a new one starts with names A-Z and the biggest saldo first.
  KandidatUrutan pilih(KandidatSortField pilihan) {
    if (pilihan == field) {
      return KandidatUrutan.values
          .firstWhere((u) => u.field == field && u.ascending != ascending);
    }
    return pilihan == KandidatSortField.nama
        ? KandidatUrutan.namaAZ
        : KandidatUrutan.saldoTerbesar;
  }
}

/// A nasabah the picker lists: active and approved. One without saldo is shown
/// but cannot be picked, so a missing name never looks like a mistake.
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

  bool get kosong => saldo <= 0;

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

  /// What was last applied to everyone, kept so the form reopens as it was.
  final JumlahUmum? jumlahUmum;
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
    this.jumlahUmum,
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
        jumlahUmum,
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
  final JumlahUmum? jumlahUmum;
  final List<DraftItemInput> items;

  const DraftInput({
    this.nama,
    required this.potonganDefault,
    this.jumlahUmum,
    required this.items,
  });

  @override
  List<Object?> get props => [nama, potonganDefault, jumlahUmum, items];
}

enum ExportBerkas {
  pdf('PDF'),
  xlsx('Excel');

  const ExportBerkas(this.label);

  final String label;
}

class DraftExport {
  final Uint8List bytes;
  final String filename;

  const DraftExport({required this.bytes, required this.filename});
}
