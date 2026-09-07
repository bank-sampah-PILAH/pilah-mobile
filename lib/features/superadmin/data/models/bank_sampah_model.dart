import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';

/// Maps the PILAH `BankSampahApprovalListSerializer` JSON to [BankSampahEntity].
class BankSampahModel extends BankSampahEntity {
  BankSampahModel({
    required super.id,
    required super.nama,
    required super.alamat,
    required super.kota,
    required super.noHpPic,
    required super.fotoKegiatan,
    required super.status,
    required super.createdAt,
    required super.pengelolaNama,
    required super.pengelolaEmail,
    required super.pengelolaNoHp,
  });

  factory BankSampahModel.fromJson(Map<String, dynamic> json) {
    final pengelola = json['pengelola_utama'] as Map<String, dynamic>?;
    final foto = json['foto_kegiatan']?.toString();
    return BankSampahModel(
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      kota: json['kota']?.toString() ?? '',
      noHpPic: json['no_hp_pic']?.toString() ?? '',
      fotoKegiatan: (foto != null && foto.isNotEmpty) ? foto : null,
      status: json['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal(),
      pengelolaNama: pengelola?['nama']?.toString(),
      pengelolaEmail: pengelola?['email']?.toString(),
      pengelolaNoHp: pengelola?['no_hp']?.toString(),
    );
  }
}
