import 'package:equatable/equatable.dart';

/// Permintaan mengganti harga satu jenis sampah.
///
/// Tanpa [berlakuMulai], harga berlaku sekarang. Dengan [berlakuMulai], harga
/// dijadwalkan mulai waktu lokal itu; harga tidak boleh berlaku surut (BR-03).
class UbahHarga extends Equatable {
  final String id;
  final int harga;
  final DateTime? berlakuMulai;

  const UbahHarga({required this.id, required this.harga, this.berlakuMulai});

  @override
  List<Object?> get props => [id, harga, berlakuMulai];
}
