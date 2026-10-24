import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/aktivitas_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/resend_wa_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';

import 'stub_api.dart';

Widget withTransaksiProviders({
  required Widget child,
  TransaksiNotifier? transaksi,
  RiwayatAktivitasNotifier? riwayat,
  NasabahNotifier? nasabah,
  HargaNotifier? harga,
}) =>
    ProviderScope(
      overrides: [
        if (transaksi != null) transaksiProvider.overrideWith(() => transaksi),
        if (riwayat != null)
          riwayatAktivitasProvider.overrideWith(() => riwayat),
        if (nasabah != null) nasabahProvider.overrideWith(() => nasabah),
        if (harga != null) hargaProvider.overrideWith(() => harga),
      ],
      child: child,
    );

/// A real [TransaksiNotifier] over the transaksi stack, with only HTTP stubbed.
RiwayatAktivitasNotifier buildRiwayatAktivitasNotifier(StubApi api) {
  final repository =
      TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network));
  return RiwayatAktivitasNotifier(
    GetAktivitasUseCase(AktivitasRepositoryImpl(api.network)),
    ExportTransaksiUseCase(repository),
  );
}

TransaksiNotifier buildTransaksiNotifier(StubApi api) {
  final repository =
      TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network));
  return TransaksiNotifier(
    GetTransaksiUseCase(repository),
    GetTransaksiDetailUseCase(repository),
    AddTransaksiUseCase(repository),
    ExportTransaksiUseCase(repository),
    ResendWaUseCase(repository),
  );
}
