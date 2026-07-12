import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_state.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_state.dart';

@lazySingleton
class DashboardCubit extends Cubit<DashboardState> {
  final NasabahCubit nasabahCubit;
  final TransaksiCubit transaksiCubit;

  late final StreamSubscription nasabahSubscription;
  late final StreamSubscription transaksiSubscription;

  DashboardCubit(this.nasabahCubit, this.transaksiCubit) : super(const DashboardState()) {
    if (nasabahCubit.state is NasabahInitial) {
      nasabahCubit.loadNasabah();
    } else {
      _calculateNasabahStats(nasabahCubit.state);
    }

    if (transaksiCubit.state is TransaksiInitial) {
      transaksiCubit.loadTransaksi();
    } else {
      _calculateTransaksiStats(transaksiCubit.state);
    }

    nasabahSubscription = nasabahCubit.stream.listen((state) {
      _calculateNasabahStats(state);
    });

    transaksiSubscription = transaksiCubit.stream.listen((state) {
      _calculateTransaksiStats(state);
    });
  }

  void _calculateNasabahStats(NasabahState state) {
    if (state is NasabahLoaded) {
      int activeNasabah = 0;
      int totalSaldo = 0;

      for (var nasabah in state.nasabahList) {
        if (nasabah.isActive == true) {
          activeNasabah++;
          final clean = nasabah.balance.replaceAll(RegExp(r'[^0-9]'), '');
          totalSaldo += int.tryParse(clean) ?? 0;
        }
      }

      emit(this.state.copyWith(
        totalNasabahAktif: activeNasabah,
        totalSaldoNasabah: totalSaldo,
      ));
    }
  }

  void _calculateTransaksiStats(TransaksiState state) {
    if (state is TransaksiLoaded) {
      int totalBerat = 0;
      int totalTrx = 0;

      for (var group in state.transaksiList) {
        var transactions = group.transactions;
        totalTrx += transactions.length;
        for (var trx in transactions) {
          var items = trx.items;
          for (var item in items) {
            String beratStr = item.berat;
            String clean = beratStr.replaceAll(RegExp(r'[^0-9]'), '');
            totalBerat += int.tryParse(clean) ?? 0;
          }
        }
      }

      emit(this.state.copyWith(
        totalSampah: totalBerat,
        totalTransaksi: totalTrx,
      ));
    }
  }

  @override
  Future<void> close() {
    nasabahSubscription.cancel();
    transaksiSubscription.cancel();
    return super.close();
  }
}
