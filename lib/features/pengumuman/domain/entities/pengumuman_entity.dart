import 'package:equatable/equatable.dart';

class PengumumanEntity extends Equatable {
  final String id;
  final String bankSampahId;
  final String judul;
  final String isi;
  final DateTime? terbitPada;
  final DateTime? masaBerlakuHingga;
  final DateTime? ditarikPada;
  final String status;

  /// Nasabah read receipt (PIL-244). Unused on the pengurus side, where the
  /// backend never sends it.
  final bool dibaca;
  final DateTime? dibacaPada;

  /// Bank sampah identity (nasabah-facing serializers only — the pengurus
  /// side already sits inside its own bank).
  final String bankSampahNama;
  final String bankSampahKota;
  final String bankSampahAlamat;

  const PengumumanEntity({
    required this.id,
    required this.bankSampahId,
    required this.judul,
    required this.isi,
    this.terbitPada,
    this.masaBerlakuHingga,
    this.ditarikPada,
    this.status = 'draft',
    this.dibaca = false,
    this.dibacaPada,
    this.bankSampahNama = '',
    this.bankSampahKota = '',
    this.bankSampahAlamat = '',
  });

  /// Effective status reported by the backend: draft, terjadwal, terbit,
  /// kedaluwarsa, or ditarik.
  bool get isDraft => status == 'draft';
  bool get isTerjadwal => status == 'terjadwal';
  bool get isTerbit => status == 'terbit';
  bool get isKedaluwarsa => status == 'kedaluwarsa';
  bool get isDitarik => status == 'ditarik';

  @override
  List<Object?> get props => [
        id,
        bankSampahId,
        judul,
        isi,
        terbitPada,
        masaBerlakuHingga,
        ditarikPada,
        status,
        dibaca,
        dibacaPada,
        bankSampahNama,
        bankSampahKota,
        bankSampahAlamat,
      ];
}
