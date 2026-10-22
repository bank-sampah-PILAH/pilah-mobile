import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/pilih_nasabah_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/riwayat_harga_cubit.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart';
import 'package:pilah_mobile/features/superadmin/presentation/providers/superadmin_provider.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/aktivitas_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import 'approved_membership.dart';
import 'auth_support.dart';
import 'dashboard_support.dart';
import 'draft_pencairan_support.dart';
import 'harga_support.dart';
import 'nasabah_support.dart';
import 'onboarding_support.dart';
import 'pencairan_support.dart';
import 'profile_support.dart';
import 'stub_api.dart';
import 'superadmin_support.dart';
import 'transaksi_support.dart';

/// Everything the real [App] normally provides, built over a stubbed API, so
/// the real router and its pages can run in a widget test.
class AppShell {
  AppShell(this.api) {
    harga = buildHargaCubit(api);
    profile = buildProfileCubit(api);
    transaksi = buildTransaksiCubit(api);
    pencairan = buildPencairanUseCases(api);
    final repo =
        TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network));
    getTransaksi = GetTransaksiUseCase(repo);
    riwayat = RiwayatAktivitasCubit(
        GetAktivitasUseCase(AktivitasRepositoryImpl(api.network)),
        ExportTransaksiUseCase(repo));
    nasabah = buildNasabahCubit(api);
    onboarding = buildOnboardingCubit(api);
    jadwal = JadwalCubit(
        JadwalRepositoryImpl(JadwalRemoteDataSourceImpl(api.network)));
    pengumuman = PengumumanCubit(
        PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network)));
    nasabahPengumuman =
        NasabahPengumumanCubit(NasabahPengumumanRepository(api.network));
    superadmin = buildSuperadminNotifier(api);
    states = StreamController<AuthenticationStates>.broadcast();
    auth = MockAuthBloc();
  }

  final StubApi api;
  late final HargaCubit harga;
  late final ProfileCubit profile;
  late final TransaksiCubit transaksi;
  late final GetTransaksiUseCase getTransaksi;
  late final PencairanUseCases pencairan;
  late final RiwayatAktivitasCubit riwayat;
  late final NasabahCubit nasabah;
  late final OnboardingCubit onboarding;
  late final JadwalCubit jadwal;
  late final PengumumanCubit pengumuman;
  late final NasabahPengumumanCubit nasabahPengumuman;
  late final SuperadminNotifier superadmin;
  late final StreamController<AuthenticationStates> states;
  late final MockAuthBloc auth;
  late final InviteTokenStore invites;
  NasabahApprovalCubit? _approval;

  /// Registers the service-locator entries the pages resolve at build time.
  Future<void> registerDi() async {
    invites = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(invites);
    di.registerSingleton<AppEnvironment>(StubEnvironment());
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    di.registerSingleton<GetDashboardStatsUseCase>(
        buildDashboardStatsUseCase(api));
    di.registerSingleton<GetTransaksiUseCase>(getTransaksi);
    di.registerSingleton<PencairanUseCases>(pencairan);
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(api.network));
    di.registerSingleton<GetBankSampahUseCase>(superadmin.getBankSampahUseCase);
    di.registerSingleton<ApproveBankSampahUseCase>(
        superadmin.approveBankSampahUseCase);
    di.registerSingleton<RejectBankSampahUseCase>(
        superadmin.rejectBankSampahUseCase);
    final useCases = buildPencairanUseCases(api);
    di.registerFactory<EditPencairanCubit>(() => EditPencairanCubit(useCases));
    di.registerFactory<RevisiPencairanCubit>(
        () => RevisiPencairanCubit(useCases));
    di.registerFactory<RiwayatHargaCubit>(() => RiwayatHargaCubit(
        GetRiwayatHargaUseCase(
            HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network)))));
    final draftRepository = buildDraftPencairanRepository(api);
    di.registerSingleton<DraftPencairanRepository>(draftRepository);
    di.registerFactory<PilihNasabahCubit>(
        () => PilihNasabahCubit(draftRepository));
    di.registerFactory<DraftEditorCubit>(
        () => DraftEditorCubit(draftRepository));
    _approval = registerApprovedMembership();
  }

  Future<void> unregisterDi() async {
    await di.unregister<InviteTokenStore>();
    await di.unregister<AppEnvironment>();
    await di.unregister<NasabahRepository>();
    await di.unregister<GetDashboardStatsUseCase>();
    await di.unregister<GetTransaksiUseCase>();
    await di.unregister<PencairanUseCases>();
    await di.unregister<NasabahPengumumanRepository>();
    await di.unregister<GetBankSampahUseCase>();
    await di.unregister<ApproveBankSampahUseCase>();
    await di.unregister<RejectBankSampahUseCase>();
    await di.unregister<EditPencairanCubit>();
    await di.unregister<RevisiPencairanCubit>();
    await di.unregister<RiwayatHargaCubit>();
    await di.unregister<DraftPencairanRepository>();
    await di.unregister<PilihNasabahCubit>();
    await di.unregister<DraftEditorCubit>();
    final approval = _approval;
    if (approval != null) await unregisterApprovedMembership(approval);
    // Not awaited: with listeners attached a broadcast controller's close()
    // only completes once they have all gone, which the torn-down tree never
    // does.
    unawaited(states.close());
    for (final close in [
      harga.close,
      profile.close,
      transaksi.close,

      riwayat.close,
      nasabah.close,
      onboarding.close,
      jadwal.close,
      pengumuman.close,
      nasabahPengumuman.close,
      // The pencairan cubits are closed by the pages that own them.
    ]) {
      // Not awaited, for the same reason as [states]: a cubit the app's own
      // BlocProvider is already closing only finishes once the torn-down tree
      // has released its listeners.
      unawaited(close());
    }
  }

  /// Puts the (mock) auth bloc in [state] and keeps it listening to [states].
  void signedInAs(AuthenticationStates state) {
    whenListen(auth, states.stream, initialState: state);
  }

  void signedInAsRole(String role,
      {String? step = 'dashboard', String? bankStatus}) {
    signedInAs(Authenticated(
        authEntity: AuthEntity(
      id: 'u1',
      name: 'Siti Aminah',
      email: 'siti@x.test',
      photoUrl: '',
      token: 't',
      role: role,
      nextStep: step,
      bankSampahStatus: bankStatus,
      bankSampahNama: 'Bank Melati',
    )));
  }

  Widget wrap(Widget app) => ProviderScope(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<NasabahCubit>.value(value: nasabah),
            BlocProvider<HargaCubit>.value(value: harga),
            BlocProvider<JadwalCubit>.value(value: jadwal),
            BlocProvider<PengumumanCubit>.value(value: pengumuman),
            BlocProvider<NasabahPengumumanCubit>.value(
                value: nasabahPengumuman),
            BlocProvider<TransaksiCubit>.value(value: transaksi),
            BlocProvider<RiwayatAktivitasCubit>.value(value: riwayat),
            BlocProvider<ProfileCubit>.value(value: profile),
            BlocProvider<AuthenticationBloc>.value(value: auth),
            BlocProvider<OnboardingCubit>.value(value: onboarding),
          ],
          child: app,
        ),
      );
}
