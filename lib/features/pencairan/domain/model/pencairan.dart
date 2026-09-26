import 'package:equatable/equatable.dart';

enum MetodePencairan {
  tunai('Tunai'),
  transfer('Transfer');

  const MetodePencairan(this.label);

  final String label;

  static MetodePencairan fromApi(String? value) =>
      value == transfer.name ? transfer : tunai;
}

class PencairanRequest extends Equatable {
  final String nasabahId;
  final int nominal;
  final MetodePencairan metode;
  final DateTime tanggal;
  final String? keterangan;

  const PencairanRequest({
    required this.nasabahId,
    required this.nominal,
    required this.metode,
    required this.tanggal,
    this.keterangan,
  });

  @override
  List<Object?> get props => [nasabahId, nominal, metode, tanggal, keterangan];
}

/// A pengurus correction of a recorded pencairan (PIL-230). Every field is
/// sent; the backend rejects an edit that changes nothing.
class EditPencairanRequest extends Equatable {
  final String id;
  final int nominal;
  final MetodePencairan metode;
  final DateTime tanggal;
  final String keterangan;
  final String alasan;

  const EditPencairanRequest({
    required this.id,
    required this.nominal,
    required this.metode,
    required this.tanggal,
    required this.keterangan,
    required this.alasan,
  });

  @override
  List<Object?> get props => [id, nominal, metode, tanggal, keterangan, alasan];
}

class Pencairan extends Equatable {
  final String id;
  final String nasabahId;
  final String nasabahNama;
  final int nominal;
  final MetodePencairan metode;
  final DateTime? tanggal;
  final String keterangan;
  final String status;
  final int saldoSebelum;
  final int saldoSesudah;
  final String dicatatOlehNama;

  /// True once a pengurus has edited this pencairan (PIL-230).
  final bool diperbarui;

  /// Earliest tanggal an edit may set; null from a backend without edits.
  final DateTime? tanggalEditMinimum;

  const Pencairan({
    required this.id,
    this.nasabahId = '',
    required this.nasabahNama,
    required this.nominal,
    required this.metode,
    required this.tanggal,
    required this.keterangan,
    required this.status,
    required this.saldoSebelum,
    required this.saldoSesudah,
    this.dicatatOlehNama = '',
    this.diperbarui = false,
    this.tanggalEditMinimum,
  });

  @override
  List<Object?> get props => [
        id,
        nasabahId,
        nasabahNama,
        nominal,
        metode,
        tanggal,
        keterangan,
        status,
        saldoSebelum,
        saldoSesudah,
        dicatatOlehNama,
        diperbarui,
        tanggalEditMinimum,
      ];
}
