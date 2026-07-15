class BankSampahEntity {
  final String id;
  final String nama;
  final String alamat;
  final String kota;
  final String noHpPic;
  final String? fotoKegiatan;
  final String status; // pending | active | rejected
  final DateTime? createdAt;
  final String? pengelolaNama;
  final String? pengelolaEmail;
  final String? pengelolaNoHp;

  BankSampahEntity({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.kota,
    required this.noHpPic,
    required this.fotoKegiatan,
    required this.status,
    required this.createdAt,
    required this.pengelolaNama,
    required this.pengelolaEmail,
    required this.pengelolaNoHp,
  });
}
