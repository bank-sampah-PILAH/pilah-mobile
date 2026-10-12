import 'package:equatable/equatable.dart';

/// Status satu versi harga dibanding waktu sekarang, dihitung backend.
enum StatusVersiHarga {
  /// Mulai berlaku di masa depan.
  terjadwal,

  /// Harga yang dipakai setoran sekarang.
  berlaku,

  /// Pernah berlaku sebelum harga sekarang.
  sebelumnya,

  /// Dikoreksi versi lain dengan waktu mulai yang sama, jadi tidak pernah
  /// (atau tidak akan) berlaku.
  digantikan,
}

/// Satu baris riwayat harga jenis sampah (PIL-331).
class VersiHarga extends Equatable {
  /// Harga per [satuan] dalam sen, persis seperti yang tersimpan (3333.99
  /// menjadi 333399): tanpa pembulatan dan tanpa `double`.
  final int hargaSen;
  final String satuan;

  /// Waktu mulai berlaku dalam UTC, seperti yang disimpan backend.
  final DateTime berlakuMulai;

  /// Nama pengurus yang mencatat; `null` untuk harga awal hasil migrasi.
  final String? dibuatOleh;
  final StatusVersiHarga status;

  const VersiHarga({
    required this.hargaSen,
    required this.satuan,
    required this.berlakuMulai,
    this.dibuatOleh,
    required this.status,
  });

  @override
  List<Object?> get props =>
      [hargaSen, satuan, berlakuMulai, dibuatOleh, status];
}
