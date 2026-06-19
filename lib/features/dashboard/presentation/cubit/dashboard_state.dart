import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final int totalNasabahAktif;
  final int totalSaldoNasabah;
  final int totalSampah;
  final int totalTransaksi;

  const DashboardState({
    this.totalNasabahAktif = 0,
    this.totalSaldoNasabah = 0,
    this.totalSampah = 0,
    this.totalTransaksi = 0,
  });

  DashboardState copyWith({
    int? totalNasabahAktif,
    int? totalSaldoNasabah,
    int? totalSampah,
    int? totalTransaksi,
  }) {
    return DashboardState(
      totalNasabahAktif: totalNasabahAktif ?? this.totalNasabahAktif,
      totalSaldoNasabah: totalSaldoNasabah ?? this.totalSaldoNasabah,
      totalSampah: totalSampah ?? this.totalSampah,
      totalTransaksi: totalTransaksi ?? this.totalTransaksi,
    );
  }

  @override
  List<Object?> get props => [
        totalNasabahAktif,
        totalSaldoNasabah,
        totalSampah,
        totalTransaksi,
      ];
}
