import 'package:pilah_mobile/features/pengumuman/domain/entities/pengumuman_entity.dart';

class PengumumanModel extends PengumumanEntity {
  const PengumumanModel({
    required super.id,
    required super.bankSampahId,
    required super.judul,
    required super.isi,
    super.terbitPada,
    super.masaBerlakuHingga,
    super.ditarikPada,
    super.status,
    super.dibaca,
    super.dibacaPada,
  });

  factory PengumumanModel.fromJson(Map<String, dynamic> json) {
    return PengumumanModel(
      id: json['id']?.toString() ?? '',
      bankSampahId: json['bank_sampah_id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      terbitPada: _parseDate(json['terbit_pada']),
      masaBerlakuHingga: _parseDate(json['masa_berlaku_hingga']),
      ditarikPada: _parseDate(json['ditarik_pada']),
      status: json['status']?.toString() ?? 'draft',
      dibaca: json['dibaca'] as bool? ?? false,
      dibacaPada: _parseDate(json['dibaca_pada']),
    );
  }

  factory PengumumanModel.fromEntity(PengumumanEntity entity) {
    return PengumumanModel(
      id: entity.id,
      bankSampahId: entity.bankSampahId,
      judul: entity.judul,
      isi: entity.isi,
      terbitPada: entity.terbitPada,
      masaBerlakuHingga: entity.masaBerlakuHingga,
      ditarikPada: entity.ditarikPada,
      status: entity.status,
      dibaca: entity.dibaca,
      dibacaPada: entity.dibacaPada,
    );
  }

  /// `terbit_pada` is always sent (null included): a null PATCH on a
  /// scheduled announcement cancels the schedule back to draft.
  Map<String, dynamic> toJson() => {
        'judul': judul.trim(),
        'isi': isi.trim(),
        'terbit_pada': terbitPada?.toUtc().toIso8601String(),
        'masa_berlaku_hingga': masaBerlakuHingga?.toUtc().toIso8601String(),
      };

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.parse(value.toString());
  }
}
