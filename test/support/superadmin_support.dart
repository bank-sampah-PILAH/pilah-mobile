import 'package:pilah_mobile/features/superadmin/data/datasources/superadmin_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/superadmin/data/repositories/superadmin_repository_impl.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_cubit.dart';

import 'stub_api.dart';

/// A real [SuperadminCubit] over the real superadmin stack, with only HTTP stubbed.
SuperadminCubit buildSuperadminCubit(StubApi api) {
  final repository =
      SuperadminRepositoryImpl(SuperadminRemoteDataSourceImpl(api.network));
  return SuperadminCubit(
    GetBankSampahUseCase(repository),
    ApproveBankSampahUseCase(repository),
    RejectBankSampahUseCase(repository),
  );
}

Map<String, dynamic> bankRow(String id,
        {String nama = 'Bank Melati',
        String status = 'pending',
        String kota = 'Bandung',
        String alamat = 'Jl. Melati 1',
        String? foto,
        String? created = '2026-09-01T10:00:00Z',
        bool withPengelola = true}) =>
    {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'kota': kota,
      'no_hp_pic': '0811',
      'foto_kegiatan': foto,
      'status': status,
      'created_at': created,
      if (withPengelola)
        'pengelola_utama': {
          'nama': 'Budi',
          'email': 'budi@x.test',
          'no_hp': '0812',
        },
    };
