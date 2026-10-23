import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/client/app_environment.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart';
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart';
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source_impl.dart';
import 'package:pilah_mobile/features/harga/data/repositories/harga_repository_impl.dart';
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/harga_provider.dart';
import 'package:pilah_mobile/features/harga/presentation/providers/riwayat_harga_provider.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:pilah_mobile/features/pengumuman/data/repositories/pengumuman_repository_impl.dart';
import 'package:pilah_mobile/features/pengumuman/domain/repositories/pengumuman_repository.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
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
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
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
    harga = buildHargaNotifier(api);
    profile = buildProfileNotifier(api);
    transaksi = buildTransaksiNotifier(api);
    pencairan = buildPencairanUseCases(api);
    final repo =
        TransaksiRepositoryImpl(TransaksiRemoteDataSourceImpl(api.network));
    getTransaksi = GetTransaksiUseCase(repo);
    riwayat = RiwayatAktivitasNotifier(
        GetAktivitasUseCase(AktivitasRepositoryImpl(api.network)),
        ExportTransaksiUseCase(repo));
    nasabah = buildNasabahNotifier(api);
    onboardingDataSource = buildOnboardingDataSource(api);
    jadwalRepository =
        JadwalRepositoryImpl(JadwalRemoteDataSourceImpl(api.network));
    jadwal = JadwalNotifier(jadwalRepository);
    pengumumanRepository =
        PengumumanRepositoryImpl(PengumumanRemoteDataSourceImpl(api.network));
    superadmin = buildSuperadminNotifier(api);
    approval = buildApprovedMembershipNotifier();
    auth = TestAuthenticationNotifier();
    authSession = TestAuthenticationSession();
  }

  final StubApi api;
  late final NasabahApprovalNotifier approval;
  late final HargaNotifier harga;
  late final TestProfileNotifier profile;
  late final TransaksiNotifier transaksi;
  late final GetTransaksiUseCase getTransaksi;
  late final PencairanUseCases pencairan;
  late final RiwayatAktivitasNotifier riwayat;
  late final NasabahNotifier nasabah;
  late final OnboardingRemoteDataSource onboardingDataSource;
  late final JadwalNotifier jadwal;
  late final JadwalRepository jadwalRepository;
  late final PengumumanRepository pengumumanRepository;
  late final SuperadminNotifier superadmin;
  late final TestAuthenticationNotifier auth;
  late final TestAuthenticationSession authSession;
  late final InviteTokenStore invites;

  /// Registers the service-locator entries the pages resolve at build time.
  Future<void> registerDi() async {
    invites = InviteTokenStore();
    di.registerSingleton<InviteTokenStore>(invites);
    di.registerSingleton<AppEnvironment>(StubEnvironment());
    di.registerSingleton<AuthenticationUseCases>(authSession);
    di.registerSingleton<LoginWithGoogleUseCase>(
        LoginWithGoogleUseCase(authSession));
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    di.registerSingleton<OnboardingRemoteDataSource>(onboardingDataSource);
    di.registerSingleton<GetDashboardStatsUseCase>(
        buildDashboardStatsUseCase(api));
    di.registerSingleton<GetTransaksiUseCase>(getTransaksi);
    di.registerSingleton<JadwalRepository>(jadwalRepository);
    di.registerSingleton<PencairanUseCases>(pencairan);
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(api.network));
    di.registerSingleton<PengumumanRepository>(pengumumanRepository);
    di.registerSingleton<GetBankSampahUseCase>(superadmin.getBankSampahUseCase);
    di.registerSingleton<ApproveBankSampahUseCase>(
        superadmin.approveBankSampahUseCase);
    di.registerSingleton<RejectBankSampahUseCase>(
        superadmin.rejectBankSampahUseCase);
    di.registerFactory<GetRiwayatHargaUseCase>(
      () => GetRiwayatHargaUseCase(
        HargaRepositoryImpl(HargaRemoteDataSourceImpl(api.network)),
      ),
    );
    final draftRepository = buildDraftPencairanRepository(api);
    di.registerSingleton<DraftPencairanRepository>(draftRepository);
  }

  Future<void> unregisterDi() async {
    await di.unregister<InviteTokenStore>();
    await di.unregister<AppEnvironment>();
    await di.unregister<AuthenticationUseCases>();
    await di.unregister<LoginWithGoogleUseCase>();
    await di.unregister<NasabahRepository>();
    await di.unregister<OnboardingRemoteDataSource>();
    await di.unregister<GetDashboardStatsUseCase>();
    await di.unregister<GetTransaksiUseCase>();
    await di.unregister<JadwalRepository>();
    await di.unregister<PencairanUseCases>();
    await di.unregister<NasabahPengumumanRepository>();
    await di.unregister<PengumumanRepository>();
    await di.unregister<GetBankSampahUseCase>();
    await di.unregister<ApproveBankSampahUseCase>();
    await di.unregister<RejectBankSampahUseCase>();
    await di.unregister<GetRiwayatHargaUseCase>();
    await di.unregister<DraftPencairanRepository>();
  }

  /// Seeds both the widget-test notifier and the fake session used by App.
  void signedInAs(AuthenticationStates state) {
    auth.setStateForTest(state);
    authSession.state = state;
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
        overrides: [
          authenticationProvider.overrideWith(() => auth),
          jadwalProvider.overrideWith(() => jadwal),
          profileProvider.overrideWith(() => profile),
          nasabahApprovalProvider.overrideWith(() => approval),
          hargaProvider.overrideWith(() => harga),
          nasabahProvider.overrideWith(() => nasabah),
          transaksiProvider.overrideWith(() => transaksi),
          riwayatAktivitasProvider.overrideWith(() => riwayat),
          riwayatHargaProvider.overrideWith(
            () => RiwayatHargaNotifier(di<GetRiwayatHargaUseCase>()),
          ),
        ],
        child: app,
      );
}

class TestAuthenticationSession
    implements AuthenticationUseCases, AuthRepository {
  AuthenticationStates state = AuthenticationInitial();

  AuthEntity? get _user =>
      state is Authenticated ? (state as Authenticated).authEntity : null;

  @override
  Future<bool> hasSession() async => _user != null;

  @override
  Future<Either<NetworkException, AuthEntity>> getMe() async {
    final user = _user;
    return user == null
        ? Left(GeneralException(message: 'No test session'))
        : Right(user);
  }

  @override
  Future<Either<NetworkException, AuthEntity>> postLogin(
      String email, String password) async {
    final user = _user ?? testAuth();
    state = Authenticated(authEntity: user);
    return Right(user);
  }

  @override
  Future<Either<NetworkException, GoogleAuthOutcome>> loginWithGoogle(
      String idToken) async {
    final user = _user ?? testAuth();
    state = Authenticated(authEntity: user);
    return Right(GoogleSession(user));
  }

  @override
  Future<Either<NetworkException, AuthEntity>> registerGoogleUser({
    required String registrationToken,
    required GoogleRegistrationRole role,
  }) async {
    final user = _user ?? testAuth();
    state = Authenticated(authEntity: user);
    return Right(user);
  }

  @override
  Future<Either<Exception, void>> saveToken(
          String accessToken, String refreshToken) async =>
      const Right(null);

  @override
  Future<Either<NetworkException, void>> logout() async {
    state = Unauthenticated();
    return const Right(null);
  }
}
