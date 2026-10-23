import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';

import 'stub_api.dart';

/// A real [NasabahNotifier] over the nasabah stack, with only HTTP stubbed.
Widget withNasabahProvider(NasabahNotifier notifier, Widget child) =>
    ProviderScope(
      overrides: [nasabahProvider.overrideWith(() => notifier)],
      child: child,
    );

class _UnusedGetNasabah extends Mock implements GetNasabahUseCase {}

class _UnusedGetActiveNasabah extends Mock implements GetActiveNasabahUseCase {}

class _UnusedGetNasabahRingkasan extends Mock
    implements GetNasabahRingkasanUseCase {}

class _UnusedAddNasabah extends Mock implements AddNasabahUseCase {}

class _UnusedUpdateNasabah extends Mock implements UpdateNasabahUseCase {}

class _UnusedActivateNasabah extends Mock implements ActivateNasabahUseCase {}

class _UnusedDeactivateNasabah extends Mock
    implements DeactivateNasabahUseCase {}

class _UnusedApproveNasabah extends Mock implements ApproveNasabahUseCase {}

class _UnusedRejectNasabah extends Mock implements RejectNasabahUseCase {}

class _UnusedSinkronProfilNasabah extends Mock
    implements SinkronProfilNasabahUseCase {}

class TestNasabahNotifier extends NasabahNotifier {
  TestNasabahNotifier({
    this.initialState = const NasabahLoaded(nasabahList: []),
    this.fetchSummary,
    this.add,
    this.update,
    this.syncProfile,
  }) : super(
          _UnusedGetNasabah(),
          _UnusedGetActiveNasabah(),
          _UnusedGetNasabahRingkasan(),
          _UnusedAddNasabah(),
          _UnusedUpdateNasabah(),
          _UnusedActivateNasabah(),
          _UnusedDeactivateNasabah(),
          _UnusedApproveNasabah(),
          _UnusedRejectNasabah(),
          _UnusedSinkronProfilNasabah(),
        );

  final NasabahState initialState;
  Future<NasabahRingkasan?> Function(String id)? fetchSummary;
  Future<NetworkException?> Function(NasabahRequest request)? add;
  Future<NetworkException?> Function(String id, NasabahRequest request)? update;
  Future<NetworkException?> Function(String id)? syncProfile;
  final requestedSummaries = <String>[];
  final addedRequests = <NasabahRequest>[];
  final updatedRequests = <(String, NasabahRequest)>[];
  final synchronizedProfiles = <String>[];

  @override
  NasabahState build() => initialState;

  @override
  Future<NasabahRingkasan?> fetchRingkasan(String id) {
    requestedSummaries.add(id);
    return fetchSummary?.call(id) ?? Future.value();
  }

  @override
  Future<NetworkException?> addNasabah(NasabahRequest request) {
    addedRequests.add(request);
    return add?.call(request) ?? Future.value();
  }

  @override
  Future<NetworkException?> updateNasabah(String id, NasabahRequest request) {
    updatedRequests.add((id, request));
    return update?.call(id, request) ?? Future.value();
  }

  @override
  Future<NetworkException?> sinkronProfil(String id) {
    synchronizedProfiles.add(id);
    return syncProfile?.call(id) ?? Future.value();
  }
}

NasabahNotifier buildNasabahNotifier(StubApi api) {
  final repository =
      NasabahRepositoryImpl(NasabahRemoteDataSourceImpl(api.network));
  return NasabahNotifier(
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
