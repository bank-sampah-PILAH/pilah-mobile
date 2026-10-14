import 'package:equatable/equatable.dart';

/// Totals for the complete server-filtered activity feed, never a page subtotal.
class AktivitasSummary extends Equatable {
  const AktivitasSummary({
    required this.jumlahTransaksi,
    required this.totalBerat,
    required this.totalSetoran,
    required this.totalPencairan,
    required this.saldo,
  });

  final int jumlahTransaksi;
  final double totalBerat;
  final int totalSetoran;
  final int totalPencairan;
  final int saldo;

  factory AktivitasSummary.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Ringkasan laporan tidak valid');
    }
    final count = _nonNegativeInt(raw, 'jumlah_transaksi');
    final deposit = _nonNegativeInt(raw, 'total_setoran');
    final payout = _nonNegativeInt(raw, 'total_pencairan');
    final weight = raw['total_berat'];
    final kg = weight is String ? double.tryParse(weight) : null;
    if (kg == null || !kg.isFinite || kg < 0) {
      throw const FormatException('Total berat tidak valid');
    }
    final balance = raw['saldo'];
    if (balance is! int || balance != deposit - payout) {
      throw const FormatException('Saldo periode tidak valid');
    }
    return AktivitasSummary(
      jumlahTransaksi: count,
      totalBerat: kg,
      totalSetoran: deposit,
      totalPencairan: payout,
      saldo: balance,
    );
  }

  static int _nonNegativeInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int || value < 0) {
      throw FormatException('$key tidak valid');
    }
    return value;
  }

  @override
  List<Object?> get props => [
        jumlahTransaksi,
        totalBerat,
        totalSetoran,
        totalPencairan,
        saldo,
      ];
}
