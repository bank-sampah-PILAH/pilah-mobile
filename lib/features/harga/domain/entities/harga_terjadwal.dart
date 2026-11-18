import 'package:equatable/equatable.dart';

/// Harga berikutnya yang sudah dijadwalkan pengurus tetapi belum berlaku.
class HargaTerjadwal extends Equatable {
  final int harga;

  /// Waktu mulai berlaku dalam UTC, seperti yang disimpan backend.
  final DateTime berlakuMulai;

  const HargaTerjadwal({required this.harga, required this.berlakuMulai});

  @override
  List<Object?> get props => [harga, berlakuMulai];
}
