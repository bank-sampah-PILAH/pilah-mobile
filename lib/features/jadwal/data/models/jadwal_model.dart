import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';

class JadwalModel extends JadwalEntity {
  const JadwalModel({
    required super.id,
    required super.bankSampahId,
    required super.jenisKegiatan,
    required super.mulaiPada,
    required super.selesaiPada,
    required super.lokasi,
    super.keterangan,
    super.cakupanPenerima,
    super.penerimaIds,
    super.status,
    super.isOverlapping,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      id: json['id']?.toString() ?? '',
      bankSampahId: json['bank_sampah_id']?.toString() ?? '',
      jenisKegiatan: json['jenis_kegiatan']?.toString() ?? '',
      mulaiPada: DateTime.parse(json['mulai_pada'].toString()),
      selesaiPada: DateTime.parse(json['selesai_pada'].toString()),
      lokasi: json['lokasi']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      cakupanPenerima: json['cakupan_penerima']?.toString() ?? 'semua_nasabah',
      penerimaIds: (json['penerima_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      status: json['status']?.toString() ?? 'draft',
      isOverlapping: json['peringatan_jadwal_bertumpuk'] as bool? ?? false,
    );
  }

  factory JadwalModel.fromEntity(JadwalEntity entity) {
    return JadwalModel(
      id: entity.id,
      bankSampahId: entity.bankSampahId,
      jenisKegiatan: entity.jenisKegiatan,
      mulaiPada: entity.mulaiPada,
      selesaiPada: entity.selesaiPada,
      lokasi: entity.lokasi,
      keterangan: entity.keterangan,
      cakupanPenerima: entity.cakupanPenerima,
      penerimaIds: entity.penerimaIds,
      status: entity.status,
      isOverlapping: entity.isOverlapping,
    );
  }

  Map<String, dynamic> toJson() => {
        'jenis_kegiatan': jenisKegiatan,
        'mulai_pada': mulaiPada.toUtc().toIso8601String(),
        'selesai_pada': selesaiPada.toUtc().toIso8601String(),
        'lokasi': lokasi.trim(),
        'keterangan': keterangan.trim(),
        'cakupan_penerima': cakupanPenerima,
        'penerima_ids': penerimaIds,
      };
}
