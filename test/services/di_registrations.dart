// Generated from lib/services/di.config.dart by listing its registrations;
// add a line here for each registration you add.
import 'package:pilah_mobile/core/constants/app_key.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:image_cropper/image_cropper.dart' show ImageCropper;
import 'package:image_picker/image_picker.dart' show ImagePicker;
import 'package:pilah_mobile/core/client/app_environment.dart'
    show AppEnvironment;
import 'package:pilah_mobile/core/client/network_service.dart'
    show NetworkService;
import 'package:pilah_mobile/core/client/network_utils.dart' show NetworkUtils;
import 'package:pilah_mobile/core/database/secure_database.dart'
    show SecureDatabase;
import 'package:pilah_mobile/core/router/invite_token_store.dart'
    show InviteTokenStore;
import 'package:pilah_mobile/core/storage/app_storage.dart' show AppStorage;
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart'
    show AuthLocalDataSources;
import 'package:pilah_mobile/features/authentication/data/remote/auth_remote_data_sources.dart'
    show AuthRemoteDataSources;
import 'package:pilah_mobile/features/authentication/domain/repository/auth_repository.dart'
    show AuthRepository;
import 'package:pilah_mobile/features/authentication/domain/use_cases/authentication_use_cases.dart'
    show AuthenticationUseCases;
import 'package:pilah_mobile/features/authentication/domain/use_cases/login_with_google_usecase.dart'
    show LoginWithGoogleUseCase;
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart'
    show AuthenticationBloc;
import 'package:pilah_mobile/features/bank_sampah_approval/data/datasources/bank_sampah_approval_remote_data_source.dart'
    show BankSampahApprovalRemoteDataSource;
import 'package:pilah_mobile/features/bank_sampah_approval/domain/repositories/bank_sampah_approval_repository.dart'
    show BankSampahApprovalRepository;
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/appeal_membership_usecase.dart'
    show AppealMembershipUseCase;
import 'package:pilah_mobile/features/bank_sampah_approval/domain/use_cases/get_nasabah_memberships_usecase.dart'
    show GetNasabahMembershipsUseCase;
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/cubit/nasabah_approval_cubit.dart'
    show NasabahApprovalCubit;
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_remote_data_source.dart'
    show DashboardRemoteDataSource;
import 'package:pilah_mobile/features/dashboard/data/datasources/dashboard_reporting_data_source.dart'
    show DashboardReportingDataSource;
import 'package:pilah_mobile/features/dashboard/domain/repositories/dashboard_repository.dart'
    show DashboardRepository;
import 'package:pilah_mobile/features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart'
    show GetDashboardStatsUseCase;
import 'package:pilah_mobile/features/draft_pencairan/data/remote/draft_pencairan_remote_data_source.dart'
    show DraftPencairanRemoteDataSource;
import 'package:pilah_mobile/features/draft_pencairan/domain/repository/draft_pencairan_repository.dart'
    show DraftPencairanRepository;
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_editor_cubit.dart'
    show DraftEditorCubit;
import 'package:pilah_mobile/features/harga/data/datasources/harga_remote_data_source.dart'
    show HargaRemoteDataSource;
import 'package:pilah_mobile/features/harga/domain/repositories/harga_repository.dart'
    show HargaRepository;
import 'package:pilah_mobile/features/harga/domain/use_cases/activate_harga_usecase.dart'
    show ActivateHargaUseCase;
import 'package:pilah_mobile/features/harga/domain/use_cases/add_harga_usecase.dart'
    show AddHargaUseCase;
import 'package:pilah_mobile/features/harga/domain/use_cases/deactivate_harga_usecase.dart'
    show DeactivateHargaUseCase;
import 'package:pilah_mobile/features/harga/domain/use_cases/get_harga_usecase.dart'
    show GetHargaUseCase;
import 'package:pilah_mobile/features/harga/domain/use_cases/update_harga_usecase.dart'
    show UpdateHargaUseCase;
import 'package:pilah_mobile/features/harga/domain/use_cases/get_riwayat_harga_usecase.dart'
    show GetRiwayatHargaUseCase;
import 'package:pilah_mobile/features/harga/domain/use_cases/ubah_harga_usecase.dart'
    show UbahHargaUseCase;
import 'package:pilah_mobile/features/harga/presentation/cubit/riwayat_harga_cubit.dart'
    show RiwayatHargaCubit;
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart'
    show HargaCubit;
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart'
    show JadwalRemoteDataSource;
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart'
    show JadwalRepository;
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart'
    show JadwalCubit;
import 'package:pilah_mobile/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart'
    show PengumumanRemoteDataSource;
import 'package:pilah_mobile/features/pengumuman/domain/repositories/pengumuman_repository.dart'
    show PengumumanRepository;
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/nasabah_pengumuman_cubit.dart'
    show NasabahPengumumanCubit;
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart'
    show PengumumanCubit;
import 'package:pilah_mobile/features/nasabah/data/datasources/nasabah_remote_data_source.dart'
    show NasabahRemoteDataSource;
import 'package:pilah_mobile/features/nasabah/domain/repositories/nasabah_repository.dart'
    show NasabahRepository;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/activate_nasabah_usecase.dart'
    show ActivateNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/add_nasabah_usecase.dart'
    show AddNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/approve_nasabah_usecase.dart'
    show ApproveNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart'
    show DeactivateNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_active_nasabah_usecase.dart'
    show GetActiveNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart'
    show GetNasabahRingkasanUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/get_nasabah_usecase.dart'
    show GetNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/reject_nasabah_usecase.dart'
    show RejectNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/sinkron_profil_nasabah_usecase.dart'
    show SinkronProfilNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/domain/use_cases/update_nasabah_usecase.dart'
    show UpdateNasabahUseCase;
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart'
    show NasabahCubit;
import 'package:pilah_mobile/features/onboarding/data/datasources/onboarding_remote_data_source.dart'
    show OnboardingRemoteDataSource;
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart'
    show OnboardingCubit;
import 'package:pilah_mobile/features/pencairan/data/remote/pencairan_remote_data_sources.dart'
    show PencairanRemoteDataSources;
import 'package:pilah_mobile/features/pencairan/domain/repository/pencairan_repository.dart'
    show PencairanRepository;
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart'
    show PencairanUseCases;
import 'package:pilah_mobile/features/pencairan/presentation/blocs/edit_pencairan_cubit.dart'
    show EditPencairanCubit;
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart'
    show RevisiPencairanCubit;
import 'package:pilah_mobile/features/profile/data/datasources/profile_remote_data_source.dart'
    show ProfileRemoteDataSource;
import 'package:pilah_mobile/features/profile/presentation/cubit/profile_cubit.dart'
    show ProfileCubit;
import 'package:pilah_mobile/features/riwayat/data/datasources/riwayat_remote_data_source.dart'
    show RiwayatRemoteDataSource;
import 'package:pilah_mobile/features/riwayat/domain/repositories/riwayat_repository.dart'
    show RiwayatRepository;
import 'package:pilah_mobile/features/riwayat/domain/use_cases/riwayat_use_cases.dart'
    show GetRiwayatHistoryUseCase, GetRiwayatSetoranDetailUseCase;
import 'package:pilah_mobile/features/riwayat/presentation/cubit/riwayat_history_cubit.dart'
    show RiwayatHistoryCubit;
import 'package:pilah_mobile/features/statement/data/remote/statement_remote_data_sources.dart'
    show StatementRemoteDataSources;
import 'package:pilah_mobile/features/statement/domain/repository/statement_repository.dart'
    show StatementRepository;
import 'package:pilah_mobile/features/statement/domain/use_cases/statement_use_cases.dart'
    show StatementUseCases;
import 'package:pilah_mobile/features/superadmin/data/datasources/superadmin_remote_data_source.dart'
    show SuperadminRemoteDataSource;
import 'package:pilah_mobile/features/superadmin/domain/repositories/superadmin_repository.dart'
    show SuperadminRepository;
import 'package:pilah_mobile/features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart'
    show ApproveBankSampahUseCase;
import 'package:pilah_mobile/features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart'
    show GetBankSampahUseCase;
import 'package:pilah_mobile/features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart'
    show RejectBankSampahUseCase;
import 'package:pilah_mobile/features/transaksi/data/datasources/transaksi_remote_data_source.dart'
    show TransaksiRemoteDataSource;
import 'package:pilah_mobile/features/transaksi/domain/repositories/aktivitas_repository.dart'
    show AktivitasRepository;
import 'package:pilah_mobile/features/transaksi/domain/repositories/transaksi_repository.dart'
    show TransaksiRepository;
import 'package:pilah_mobile/features/transaksi/domain/use_cases/add_transaksi_usecase.dart'
    show AddTransaksiUseCase;
import 'package:pilah_mobile/features/transaksi/domain/use_cases/export_transaksi_usecase.dart'
    show ExportTransaksiUseCase;
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_aktivitas_usecase.dart'
    show GetAktivitasUseCase;
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart'
    show GetTransaksiDetailUseCase;
import 'package:pilah_mobile/features/transaksi/domain/use_cases/get_transaksi_usecase.dart'
    show GetTransaksiUseCase;
import 'package:pilah_mobile/features/transaksi/domain/use_cases/resend_wa_usecase.dart'
    show ResendWaUseCase;
import 'package:pilah_mobile/features/transaksi/presentation/cubit/riwayat_aktivitas_cubit.dart'
    show RiwayatAktivitasCubit;
import 'package:pilah_mobile/features/transaksi/presentation/cubit/transaksi_cubit.dart'
    show TransaksiCubit;

/// Every registration in the generated `di.config.dart`: a label, the only
/// environment it is registered for (`null` for all), and how to resolve it.
final diRegistrations = <(String, String?, Object Function())>[
  ('ImagePicker', null, () => di<ImagePicker>()),
  ('ImageCropper', null, () => di<ImageCropper>()),
  ('InviteTokenStore', null, () => di<InviteTokenStore>()),
  ('AppEnvironment', AppKey.devEnv, () => di<AppEnvironment>()),
  (
    'AppStorage (flutter_secure_storage)',
    null,
    () => di<AppStorage>(instanceName: 'flutter_secure_storage')
  ),
  (
    'AppStorage (shared_preferences)',
    null,
    () => di<AppStorage>(instanceName: 'shared_preferences')
  ),
  ('SecureDatabase', null, () => di<SecureDatabase>()),
  ('NetworkUtils', null, () => di<NetworkUtils>()),
  ('AppEnvironment', AppKey.prodEnv, () => di<AppEnvironment>()),
  ('AuthLocalDataSources', null, () => di<AuthLocalDataSources>()),
  ('NetworkService', null, () => di<NetworkService>()),
  (
    'DraftPencairanRemoteDataSource',
    null,
    () => di<DraftPencairanRemoteDataSource>()
  ),
  ('OnboardingRemoteDataSource', null, () => di<OnboardingRemoteDataSource>()),
  ('PencairanRemoteDataSources', null, () => di<PencairanRemoteDataSources>()),
  ('SuperadminRemoteDataSource', null, () => di<SuperadminRemoteDataSource>()),
  ('TransaksiRemoteDataSource', null, () => di<TransaksiRemoteDataSource>()),
  ('AktivitasRepository', null, () => di<AktivitasRepository>()),
  ('GetAktivitasUseCase', null, () => di<GetAktivitasUseCase>()),
  (
    'DashboardReportingDataSource',
    null,
    () => di<DashboardReportingDataSource>()
  ),
  ('DashboardRemoteDataSource', null, () => di<DashboardRemoteDataSource>()),
  ('JadwalRemoteDataSource', null, () => di<JadwalRemoteDataSource>()),
  ('PengumumanRemoteDataSource', null, () => di<PengumumanRemoteDataSource>()),
  (
    'BankSampahApprovalRemoteDataSource',
    null,
    () => di<BankSampahApprovalRemoteDataSource>()
  ),
  ('ProfileRemoteDataSource', null, () => di<ProfileRemoteDataSource>()),
  ('AuthRemoteDataSources', null, () => di<AuthRemoteDataSources>()),
  ('JadwalRepository', null, () => di<JadwalRepository>()),
  ('PengumumanRepository', null, () => di<PengumumanRepository>()),
  ('StatementRemoteDataSources', null, () => di<StatementRemoteDataSources>()),
  ('HargaRemoteDataSource', null, () => di<HargaRemoteDataSource>()),
  ('NasabahRemoteDataSource', null, () => di<NasabahRemoteDataSource>()),
  ('RiwayatRemoteDataSource', null, () => di<RiwayatRemoteDataSource>()),
  ('RiwayatRepository', null, () => di<RiwayatRepository>()),
  ('ProfileCubit', null, () => di<ProfileCubit>()),
  (
    'BankSampahApprovalRepository',
    null,
    () => di<BankSampahApprovalRepository>()
  ),
  ('DraftPencairanRepository', null, () => di<DraftPencairanRepository>()),
  ('TransaksiRepository', null, () => di<TransaksiRepository>()),
  ('OnboardingCubit', null, () => di<OnboardingCubit>()),
  ('NasabahPengumumanCubit', null, () => di<NasabahPengumumanCubit>()),
  ('PengumumanCubit', null, () => di<PengumumanCubit>()),
  ('NasabahRepository', null, () => di<NasabahRepository>()),
  ('StatementRepository', null, () => di<StatementRepository>()),
  ('DraftEditorCubit', null, () => di<DraftEditorCubit>()),
  ('PencairanRepository', null, () => di<PencairanRepository>()),
  ('HargaRepository', null, () => di<HargaRepository>()),
  ('SuperadminRepository', null, () => di<SuperadminRepository>()),
  ('AuthRepository', null, () => di<AuthRepository>()),
  ('JadwalCubit', null, () => di<JadwalCubit>()),
  ('AppealMembershipUseCase', null, () => di<AppealMembershipUseCase>()),
  (
    'GetNasabahMembershipsUseCase',
    null,
    () => di<GetNasabahMembershipsUseCase>()
  ),
  ('DashboardRepository', null, () => di<DashboardRepository>()),
  ('NasabahApprovalCubit', null, () => di<NasabahApprovalCubit>()),
  ('ActivateNasabahUseCase', null, () => di<ActivateNasabahUseCase>()),
  ('AddNasabahUseCase', null, () => di<AddNasabahUseCase>()),
  ('ApproveNasabahUseCase', null, () => di<ApproveNasabahUseCase>()),
  ('DeactivateNasabahUseCase', null, () => di<DeactivateNasabahUseCase>()),
  ('GetActiveNasabahUseCase', null, () => di<GetActiveNasabahUseCase>()),
  ('GetNasabahRingkasanUseCase', null, () => di<GetNasabahRingkasanUseCase>()),
  ('GetNasabahUseCase', null, () => di<GetNasabahUseCase>()),
  ('RejectNasabahUseCase', null, () => di<RejectNasabahUseCase>()),
  (
    'SinkronProfilNasabahUseCase',
    null,
    () => di<SinkronProfilNasabahUseCase>()
  ),
  ('UpdateNasabahUseCase', null, () => di<UpdateNasabahUseCase>()),
  ('AuthenticationUseCases', null, () => di<AuthenticationUseCases>()),
  ('GetRiwayatHistoryUseCase', null, () => di<GetRiwayatHistoryUseCase>()),
  (
    'GetRiwayatSetoranDetailUseCase',
    null,
    () => di<GetRiwayatSetoranDetailUseCase>()
  ),
  ('LoginWithGoogleUseCase', null, () => di<LoginWithGoogleUseCase>()),
  ('AuthenticationBloc', null, () => di<AuthenticationBloc>()),
  ('StatementUseCases', null, () => di<StatementUseCases>()),
  ('ApproveBankSampahUseCase', null, () => di<ApproveBankSampahUseCase>()),
  ('GetBankSampahUseCase', null, () => di<GetBankSampahUseCase>()),
  ('RejectBankSampahUseCase', null, () => di<RejectBankSampahUseCase>()),
  ('AddTransaksiUseCase', null, () => di<AddTransaksiUseCase>()),
  ('ExportTransaksiUseCase', null, () => di<ExportTransaksiUseCase>()),
  ('GetTransaksiDetailUseCase', null, () => di<GetTransaksiDetailUseCase>()),
  ('GetTransaksiUseCase', null, () => di<GetTransaksiUseCase>()),
  ('ResendWaUseCase', null, () => di<ResendWaUseCase>()),
  ('TransaksiCubit', null, () => di<TransaksiCubit>()),
  ('PencairanUseCases', null, () => di<PencairanUseCases>()),
  ('ActivateHargaUseCase', null, () => di<ActivateHargaUseCase>()),
  ('AddHargaUseCase', null, () => di<AddHargaUseCase>()),
  ('DeactivateHargaUseCase', null, () => di<DeactivateHargaUseCase>()),
  ('GetHargaUseCase', null, () => di<GetHargaUseCase>()),
  ('UpdateHargaUseCase', null, () => di<UpdateHargaUseCase>()),
  ('UbahHargaUseCase', null, () => di<UbahHargaUseCase>()),
  ('GetRiwayatHargaUseCase', null, () => di<GetRiwayatHargaUseCase>()),
  ('RiwayatHargaCubit', null, () => di<RiwayatHargaCubit>()),
  ('GetDashboardStatsUseCase', null, () => di<GetDashboardStatsUseCase>()),
  ('NasabahCubit', null, () => di<NasabahCubit>()),
  ('EditPencairanCubit', null, () => di<EditPencairanCubit>()),
  ('RevisiPencairanCubit', null, () => di<RevisiPencairanCubit>()),
  ('RiwayatHistoryCubit', null, () => di<RiwayatHistoryCubit>()),
  ('RiwayatAktivitasCubit', null, () => di<RiwayatAktivitasCubit>()),
  ('HargaCubit', null, () => di<HargaCubit>()),
];
