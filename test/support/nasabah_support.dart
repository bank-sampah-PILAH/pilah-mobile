import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/nasabah/data/repositories/nasabah_repository_impl.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/sinkron_profil_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';

import 'stub_api.dart';

/// A real [NasabahCubit] over the real nasabah stack, with only HTTP stubbed.
NasabahCubit buildNasabahCubit(StubApi api) {
  final repository =
      NasabahRepositoryImpl(NasabahRemoteDataSourceImpl(api.network));
  return NasabahCubit(
    GetNasabahUseCase(repository),
    GetActiveNasabahUseCase(repository),
    GetNasabahRingkasanUseCase(repository),
    AddNasabahUseCase(repository),
    UpdateNasabahUseCase(repository),
    ActivateNasabahUseCase(repository),
    DeactivateNasabahUseCase(repository),
    ApproveNasabahUseCase(repository),
    RejectNasabahUseCase(repository),
    SinkronProfilNasabahUseCase(repository),
  );
}

/// One nasabah row as the API serialises it.
Map<String, dynamic> nasabahRow(
  String id, {
  String nama = 'Budi Santoso',
  bool active = true,
  String status = 'approved',
  String saldo = '25000',
  bool punyaAkun = false,
}) =>
    {
      'id': id,
      'kode': 'NAS-$id',
      'nama': nama,
      'email': '$id@x.test',
      'no_hp': '0812$id',
      'total_saldo': saldo,
      'is_active': active,
      'alamat': 'Jl. Melati $id',
      'jenis_kelamin': 'laki-laki',
      'tanggal_lahir': '1990-04-17',
      'tanggal_daftar': '2026-01-02T03:04:05Z',
      'status': status,
      'punya_akun': punyaAkun,
    };

/// A DRF-paginated list envelope.
Map<String, dynamic> nasabahPage(List<Map<String, dynamic>> rows,
        {int? count, bool hasNext = false}) =>
    {
      'count': count ?? rows.length,
      'next': hasNext ? 'http://api.test/next' : null,
      'results': rows,
    };
