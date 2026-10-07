import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/resend_wa_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';

import 'stub_api.dart';

/// A real [TransaksiCubit] over the real transaksi stack, with only HTTP stubbed.
TransaksiCubit buildTransaksiCubit(StubApi api) {
  final repository =
      TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network));
  return TransaksiCubit(
    GetTransaksiUseCase(repository),
    GetTransaksiDetailUseCase(repository),
    AddTransaksiUseCase(repository),
    ExportTransaksiUseCase(repository),
    ResendWaUseCase(repository),
  );
}
