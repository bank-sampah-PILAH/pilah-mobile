import 'package:equatable/equatable.dart';

class JadwalEntity extends Equatable {
  final String id;
  final String bankSampahId;
  final String jenisKegiatan;
  final DateTime mulaiPada;
  final DateTime selesaiPada;
  final String lokasi;
  final String keterangan;
  final String cakupanPenerima;
  final List<String> penerimaIds;
  final String status;
  final bool isOverlapping;

  const JadwalEntity({
    required this.id,
    required this.bankSampahId,
    required this.jenisKegiatan,
    required this.mulaiPada,
    required this.selesaiPada,
    required this.lokasi,
    this.keterangan = '',
    this.cakupanPenerima = 'semua_nasabah',
    this.penerimaIds = const [],
    this.status = 'draft',
    this.isOverlapping = false,
  });

  bool get isPublished => status == 'diterbitkan';
  bool get isCancelled => status == 'dibatalkan';
  bool get isCompleted => status == 'selesai';

  @override
  List<Object?> get props => [
        id,
        bankSampahId,
        jenisKegiatan,
        mulaiPada,
        selesaiPada,
        lokasi,
        keterangan,
        cakupanPenerima,
        penerimaIds,
        status,
        isOverlapping,
      ];
}
