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

class Pencairan extends Equatable {
  final String id;
  final String nasabahNama;
  final int nominal;
  final MetodePencairan metode;
  final DateTime? tanggal;
  final String keterangan;
  final String status;
  final int saldoSebelum;
  final int saldoSesudah;

  const Pencairan({
    required this.id,
    required this.nasabahNama,
    required this.nominal,
    required this.metode,
    required this.tanggal,
    required this.keterangan,
    required this.status,
    required this.saldoSebelum,
    required this.saldoSesudah,
  });

  @override
  List<Object?> get props => [
        id,
        nasabahNama,
        nominal,
        metode,
        tanggal,
        keterangan,
        status,
        saldoSebelum,
        saldoSesudah,
      ];
}
