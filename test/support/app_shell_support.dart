import 'package:pilah_mobile/features/transaksi/data/repositories/aktivitas_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart';
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pilah_mobile/features/dashboard/presentation/cubit/recent_activity_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pilah_mobile/features/superadmin/presentation/cubit/superadmin_cubit.dart';
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/transaksi/data/repositories/transaksi_repository_impl.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart';
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import 'approved_membership.dart';
import 'auth_support.dart';
import 'dashboard_support.dart';
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
    dashboard = buildDashboardCubit(api);
    final pencairan = buildPencairanUseCases(api);
    final repo =
        TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network));
    recent = RecentActivityCubit(GetTransaksiUseCase(repo), pencairan);
    riwayat = RiwayatAktivitasCubit(
        GetAktivitasUseCase(AktivitasRepositoryImpl(api.network)),
        ExportTransaksiUseCase(repo));
    nasabah = buildNasabahCubit(api);
    onboarding = buildOnboardingCubit(api);
    jadwal = JadwalCubit(
        JadwalRepositoryImpl(JadwalRemoteDataSourceImpl(api.network)));
    pencairanCubit = PencairanCubit(pencairan);
    superadmin = buildSuperadminCubit(api);
    states = StreamController<AuthenticationStates>.broadcast();
    auth = MockAuthBloc();
  }

  final StubApi api;
  late final HargaCubit harga;
  late final ProfileCubit profile;
  late final TransaksiCubit transaksi;
  late final DashboardCubit dashboard;
  late final RecentActivityCubit recent;
  late final RiwayatAktivitasCubit riwayat;
  late final NasabahCubit nasabah;
  late final OnboardingCubit onboarding;
  late final JadwalCubit jadwal;
  late final PencairanCubit pencairanCubit;
  late final SuperadminCubit superadmin;
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
    di.registerFactory<SuperadminCubit>(() => superadmin);
    di.registerFactory<PencairanCubit>(() => pencairanCubit);
    final useCases = buildPencairanUseCases(api);
    di.registerFactory<EditPencairanCubit>(() => EditPencairanCubit(useCases));
    di.registerFactory<RevisiPencairanCubit>(
        () => RevisiPencairanCubit(useCases));
    di.registerFactory<RiwayatPencairanCubit>(
        () => RiwayatPencairanCubit(useCases));
    _approval = registerApprovedMembership();
  }

  Future<void> unregisterDi() async {
    await di.unregister<InviteTokenStore>();
    await di.unregister<AppEnvironment>();
    await di.unregister<NasabahRepository>();
    await di.unregister<SuperadminCubit>();
    await di.unregister<PencairanCubit>();
    await di.unregister<EditPencairanCubit>();
    await di.unregister<RevisiPencairanCubit>();
    await di.unregister<RiwayatPencairanCubit>();
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
      dashboard.close,
      recent.close,
      riwayat.close,
      nasabah.close,
      onboarding.close,
      jadwal.close,
      // The pencairan and superadmin cubits are closed by the pages that own
      // them (BlocProvider.create), and closing them again never completes.
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

  Widget wrap(Widget app) => MultiBlocProvider(
        providers: [
          BlocProvider<NasabahCubit>.value(value: nasabah),
          BlocProvider<HargaCubit>.value(value: harga),
          BlocProvider<JadwalCubit>.value(value: jadwal),
          BlocProvider<TransaksiCubit>.value(value: transaksi),
          BlocProvider<DashboardCubit>.value(value: dashboard),
          BlocProvider<RecentActivityCubit>.value(value: recent),
          BlocProvider<RiwayatAktivitasCubit>.value(value: riwayat),
          BlocProvider<ProfileCubit>.value(value: profile),
          BlocProvider<AuthenticationBloc>.value(value: auth),
          BlocProvider<OnboardingCubit>.value(value: onboarding),
        ],
        child: app,
      );
}
