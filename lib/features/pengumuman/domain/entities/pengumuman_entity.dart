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

  const PengumumanEntity({
    required this.id,
    required this.bankSampahId,
    required this.judul,
    required this.isi,
    this.terbitPada,
    this.masaBerlakuHingga,
    this.ditarikPada,
    this.status = 'draft',
  });

  /// Effective status reported by the backend: draft, terjadwal, terbit,
  /// kedaluwarsa, or ditarik.
  bool get isDraft => status == 'draft';
  bool get isTerjadwal => status == 'terjadwal';
  bool get isTerbit => status == 'terbit';
  bool get isKedaluwarsa => status == 'kedaluwarsa';
  bool get isDitarik => status == 'ditarik';
  bool get isBaru => status == 'terbit' && ditarikPada == null;

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
      ];
}
