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
    final count = raw['jumlah_transaksi'];
    if (count is! int || count < 0) {
      throw const FormatException('Jumlah transaksi tidak valid');
    }
    final deposit = raw['total_setoran'];
    if (deposit is! int || deposit < 0) {
      throw const FormatException('Nilai setoran tidak valid');
    }
    final payout = raw['total_pencairan'];
    if (payout is! int || payout < 0) {
      throw const FormatException('Total pencairan tidak valid');
    }
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

  @override
  List<Object?> get props => [
        jumlahTransaksi,
        totalBerat,
        totalSetoran,
        totalPencairan,
        saldo,
      ];
}
