import 'package:equatable/equatable.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final int totalKasBulanIni;
  final int totalNasabahAktif;
  final double totalSampahKg;
  final int totalTransaksi;
  final String? error;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.totalKasBulanIni = 0,
    this.totalNasabahAktif = 0,
    this.totalSampahKg = 0,
    this.totalTransaksi = 0,
    this.error,
  });

  bool get isLoaded => status == DashboardStatus.loaded;

  DashboardState copyWith({
    DashboardStatus? status,
    int? totalKasBulanIni,
    int? totalNasabahAktif,
    double? totalSampahKg,
    int? totalTransaksi,
    String? error,
  }) {
    return DashboardState(
      status: status ?? this.status,
      totalKasBulanIni: totalKasBulanIni ?? this.totalKasBulanIni,
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
        totalNasabahAktif,
        totalSampahKg,
        totalTransaksi,
        error,
      ];
}
