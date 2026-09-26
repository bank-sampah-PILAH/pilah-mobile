import 'package:equatable/equatable.dart';

import 'pencairan.dart';

/// A replaced version of a pencairan, with why, who and when it was replaced.
class RevisiPencairan extends Equatable {
  final int versi;
  final DateTime? tanggal;
  final int nominal;
  final MetodePencairan metode;
  final String keterangan;
  final int saldoSebelum;
  final int saldoSesudah;
  final String alasan;
  final String diubahOlehNama;
  final DateTime? diubahPada;

  const RevisiPencairan({
    required this.versi,
    required this.tanggal,
    required this.nominal,
    required this.metode,
    required this.keterangan,
    required this.saldoSebelum,
    required this.saldoSesudah,
    required this.alasan,
    required this.diubahOlehNama,
    required this.diubahPada,
  });

  @override
  List<Object?> get props => [
        versi,
        tanggal,
        nominal,
        metode,
        keterangan,
        saldoSebelum,
        saldoSesudah,
        alasan,
        diubahOlehNama,
        diubahPada,
      ];
}

/// `GET /api/v1/pencairan/{id}/riwayat`: the current pencairan and its replaced
/// versions, newest first. Pengurus only.
class RiwayatRevisiPencairan extends Equatable {
  final Pencairan pencairan;
  final List<RevisiPencairan> revisi;

  const RiwayatRevisiPencairan({required this.pencairan, required this.revisi});

  @override
  List<Object?> get props => [pencairan, revisi];
}
