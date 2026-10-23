import 'package:equatable/equatable.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final int totalKasBulanIni;
  final int? totalSaldoNasabah;
  final int totalNasabahAktif;
  final double totalSampahKg;
  final int totalTransaksi;
  final String? error;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.totalKasBulanIni = 0,
    this.totalSaldoNasabah,
    this.totalNasabahAktif = 0,
    this.totalSampahKg = 0,
    this.totalTransaksi = 0,
    this.error,
  });

  bool get isLoaded => status == DashboardStatus.loaded;

  DashboardState copyWith({
    DashboardStatus? status,
    int? totalKasBulanIni,
    int? totalSaldoNasabah,
    int? totalNasabahAktif,
    double? totalSampahKg,
    int? totalTransaksi,
    String? error,
  }) {
    return DashboardState(
      status: status ?? this.status,
      totalKasBulanIni: totalKasBulanIni ?? this.totalKasBulanIni,
      totalSaldoNasabah: totalSaldoNasabah ?? this.totalSaldoNasabah,
      totalNasabahAktif: totalNasabahAktif ?? this.totalNasabahAktif,
      totalSampahKg: totalSampahKg ?? this.totalSampahKg,
      totalTransaksi: totalTransaksi ?? this.totalTransaksi,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        totalKasBulanIni,
        totalSaldoNasabah,
        totalNasabahAktif,
        totalSampahKg,
        totalTransaksi,
        error,
      ];
}
