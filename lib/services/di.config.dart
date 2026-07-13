// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/client/app_environment.dart' as _i119;
import '../core/client/network_service.dart' as _i941;
import '../core/client/network_utils.dart' as _i936;
import '../core/database/secure_database.dart' as _i124;
import '../core/storage/app_storage.dart' as _i812;
import '../core/storage/storage_module.dart' as _i624;
import '../features/authentication/data/auth_repository_impl.dart' as _i493;
import '../features/authentication/data/local/auth_local_data_sources.dart'
    as _i981;
import '../features/authentication/data/remote/auth_remote_data_sources.dart'
    as _i24;
import '../features/authentication/domain/authentication_interactor.dart'
    as _i56;
import '../features/authentication/domain/repository/auth_repository.dart'
    as _i888;
import '../features/authentication/domain/use_cases/authentication_use_cases.dart'
    as _i521;
import '../features/authentication/domain/use_cases/login_with_google_usecase.dart'
    as _i934;
import '../features/authentication/presentation/blocs/authentication_bloc.dart'
    as _i960;
import '../features/dashboard/data/datasources/dashboard_remote_data_source.dart'
    as _i377;
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart'
    as _i650;
import '../features/dashboard/domain/repositories/dashboard_repository.dart'
    as _i602;
import '../features/dashboard/domain/use_cases/get_dashboard_stats_usecase.dart'
    as _i137;
import '../features/dashboard/presentation/cubit/dashboard_cubit.dart' as _i932;
import '../features/harga/data/datasources/harga_remote_data_source.dart'
    as _i960;
import '../features/harga/data/datasources/harga_remote_data_source_impl.dart'
    as _i74;
import '../features/harga/data/repositories/harga_repository_impl.dart'
    as _i922;
import '../features/harga/domain/repositories/harga_repository.dart' as _i40;
import '../features/harga/domain/use_cases/activate_harga_usecase.dart'
    as _i520;
import '../features/harga/domain/use_cases/add_harga_usecase.dart' as _i948;
import '../features/harga/domain/use_cases/deactivate_harga_usecase.dart'
    as _i989;
import '../features/harga/domain/use_cases/get_harga_usecase.dart' as _i1009;
import '../features/harga/domain/use_cases/update_harga_usecase.dart' as _i240;
import '../features/harga/presentation/cubit/harga_cubit.dart' as _i815;
import '../features/nasabah/data/datasources/nasabah_remote_data_source.dart'
    as _i307;
import '../features/nasabah/data/datasources/nasabah_remote_data_source_impl.dart'
    as _i990;
import '../features/nasabah/data/repositories/nasabah_repository_impl.dart'
    as _i1026;
import '../features/nasabah/domain/repositories/nasabah_repository.dart'
    as _i127;
import '../features/nasabah/domain/use_cases/activate_nasabah_usecase.dart'
    as _i449;
import '../features/nasabah/domain/use_cases/add_nasabah_usecase.dart' as _i532;
import '../features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart'
    as _i850;
import '../features/nasabah/domain/use_cases/get_nasabah_ringkasan_usecase.dart'
    as _i296;
import '../features/nasabah/domain/use_cases/get_nasabah_usecase.dart' as _i789;
import '../features/nasabah/domain/use_cases/update_nasabah_usecase.dart'
    as _i524;
import '../features/nasabah/presentation/cubit/nasabah_cubit.dart' as _i958;
import '../features/onboarding/data/datasources/onboarding_remote_data_source.dart'
    as _i247;
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i244;
import '../features/profile/data/datasources/profile_remote_data_source.dart'
    as _i1053;
import '../features/profile/presentation/cubit/profile_cubit.dart' as _i300;
import '../features/superadmin/data/datasources/superadmin_remote_data_source.dart'
    as _i309;
import '../features/superadmin/data/datasources/superadmin_remote_data_source_impl.dart'
    as _i495;
import '../features/superadmin/data/repositories/superadmin_repository_impl.dart'
    as _i811;
import '../features/superadmin/domain/repositories/superadmin_repository.dart'
    as _i260;
import '../features/superadmin/domain/use_cases/approve_bank_sampah_usecase.dart'
    as _i958;
import '../features/superadmin/domain/use_cases/get_bank_sampah_usecase.dart'
    as _i268;
import '../features/superadmin/domain/use_cases/reject_bank_sampah_usecase.dart'
    as _i868;
import '../features/superadmin/presentation/cubit/superadmin_cubit.dart'
    as _i174;
import '../features/transaksi/data/datasources/transaksi_remote_data_source.dart'
    as _i881;
import '../features/transaksi/data/datasources/transaksi_remote_data_source_impl.dart'
    as _i659;
import '../features/transaksi/data/repositories/transaksi_repository_impl.dart'
    as _i1041;
import '../features/transaksi/domain/repositories/transaksi_repository.dart'
    as _i1031;
import '../features/transaksi/domain/use_cases/add_transaksi_usecase.dart'
    as _i839;
import '../features/transaksi/domain/use_cases/export_transaksi_usecase.dart'
    as _i67;
import '../features/transaksi/domain/use_cases/get_transaksi_detail_usecase.dart'
    as _i218;
import '../features/transaksi/domain/use_cases/get_transaksi_usecase.dart'
    as _i383;
import '../features/transaksi/presentation/cubit/transaksi_cubit.dart' as _i474;

const String _dev = 'dev';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final storageModule = _$StorageModule();
    gh.factory<_i119.AppEnvironment>(
      () => _i119.DevEnvironment(),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i812.AppStorage>(
      () => storageModule.flutterSecureStorage,
      instanceName: 'flutter_secure_storage',
    );
    gh.lazySingleton<_i812.AppStorage>(
      () => storageModule.sharedPreferences,
      instanceName: 'shared_preferences',
    );
    gh.lazySingleton<_i124.SecureDatabase>(
        () => const _i124.SecureDatabaseImpl());
    gh.factory<_i119.AppEnvironment>(
      () => _i119.ProdEnvironment(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i936.NetworkUtils>(
        () => _i936.NetworkUtils(gh<_i124.SecureDatabase>()));
    gh.lazySingleton<_i981.AuthLocalDataSources>(
        () => _i981.AuthLocalDataSourcesImpl(
              gh<_i124.SecureDatabase>(),
              gh<_i936.NetworkUtils>(),
            ));
    gh.lazySingleton<_i941.NetworkService>(() => _i941.NetworkService(
          environment: gh<_i119.AppEnvironment>(),
          networkUtils: gh<_i936.NetworkUtils>(),
        ));
    gh.lazySingleton<_i247.OnboardingRemoteDataSource>(
        () => _i247.OnboardingRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i309.SuperadminRemoteDataSource>(
        () => _i495.SuperadminRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i244.OnboardingCubit>(
        () => _i244.OnboardingCubit(gh<_i247.OnboardingRemoteDataSource>()));
    gh.lazySingleton<_i377.DashboardRemoteDataSource>(
        () => _i377.DashboardRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i881.TransaksiRemoteDataSource>(
        () => _i659.TransaksiRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i1053.ProfileRemoteDataSource>(
        () => _i1053.ProfileRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i24.AuthRemoteDataSources>(
        () => _i24.AuthRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i307.NasabahRemoteDataSource>(
        () => _i990.NasabahRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i960.HargaRemoteDataSource>(
        () => _i74.HargaRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i260.SuperadminRepository>(() =>
        _i811.SuperadminRepositoryImpl(gh<_i309.SuperadminRemoteDataSource>()));
    gh.lazySingleton<_i888.AuthRepository>(() => _i493.AuthRepositoryImpl(
          gh<_i24.AuthRemoteDataSources>(),
          gh<_i981.AuthLocalDataSources>(),
        ));
    gh.lazySingleton<_i40.HargaRepository>(
        () => _i922.HargaRepositoryImpl(gh<_i960.HargaRemoteDataSource>()));
    gh.lazySingleton<_i127.NasabahRepository>(() =>
        _i1026.NasabahRepositoryImpl(gh<_i307.NasabahRemoteDataSource>()));
    gh.lazySingleton<_i602.DashboardRepository>(() =>
        _i650.DashboardRepositoryImpl(gh<_i377.DashboardRemoteDataSource>()));
    gh.lazySingleton<_i137.GetDashboardStatsUseCase>(
        () => _i137.GetDashboardStatsUseCase(gh<_i602.DashboardRepository>()));
    gh.lazySingleton<_i521.AuthenticationUseCases>(
        () => _i56.AuthenticationInteractor(gh<_i888.AuthRepository>()));
    gh.factory<_i300.ProfileCubit>(
        () => _i300.ProfileCubit(gh<_i1053.ProfileRemoteDataSource>()));
    gh.lazySingleton<_i1031.TransaksiRepository>(() =>
        _i1041.TransaksiRepositoryImpl(gh<_i881.TransaksiRemoteDataSource>()));
    gh.lazySingleton<_i934.LoginWithGoogleUseCase>(
        () => _i934.LoginWithGoogleUseCase(gh<_i888.AuthRepository>()));
    gh.lazySingleton<_i958.ApproveBankSampahUseCase>(
        () => _i958.ApproveBankSampahUseCase(gh<_i260.SuperadminRepository>()));
    gh.lazySingleton<_i268.GetBankSampahUseCase>(
        () => _i268.GetBankSampahUseCase(gh<_i260.SuperadminRepository>()));
    gh.lazySingleton<_i868.RejectBankSampahUseCase>(
        () => _i868.RejectBankSampahUseCase(gh<_i260.SuperadminRepository>()));
    gh.factory<_i960.AuthenticationBloc>(() => _i960.AuthenticationBloc(
          gh<_i521.AuthenticationUseCases>(),
          gh<_i934.LoginWithGoogleUseCase>(),
        ));
    gh.lazySingleton<_i449.ActivateNasabahUseCase>(
        () => _i449.ActivateNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i532.AddNasabahUseCase>(
        () => _i532.AddNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i850.DeactivateNasabahUseCase>(
        () => _i850.DeactivateNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i296.GetNasabahRingkasanUseCase>(
        () => _i296.GetNasabahRingkasanUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i789.GetNasabahUseCase>(
        () => _i789.GetNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i524.UpdateNasabahUseCase>(
        () => _i524.UpdateNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i932.DashboardCubit>(
        () => _i932.DashboardCubit(gh<_i137.GetDashboardStatsUseCase>()));
    gh.factory<_i174.SuperadminCubit>(() => _i174.SuperadminCubit(
          gh<_i268.GetBankSampahUseCase>(),
          gh<_i958.ApproveBankSampahUseCase>(),
          gh<_i868.RejectBankSampahUseCase>(),
        ));
    gh.lazySingleton<_i520.ActivateHargaUseCase>(
        () => _i520.ActivateHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i948.AddHargaUseCase>(
        () => _i948.AddHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i989.DeactivateHargaUseCase>(
        () => _i989.DeactivateHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i1009.GetHargaUseCase>(
        () => _i1009.GetHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i240.UpdateHargaUseCase>(
        () => _i240.UpdateHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i958.NasabahCubit>(() => _i958.NasabahCubit(
          gh<_i789.GetNasabahUseCase>(),
          gh<_i296.GetNasabahRingkasanUseCase>(),
          gh<_i532.AddNasabahUseCase>(),
          gh<_i524.UpdateNasabahUseCase>(),
          gh<_i449.ActivateNasabahUseCase>(),
          gh<_i850.DeactivateNasabahUseCase>(),
        ));
    gh.lazySingleton<_i839.AddTransaksiUseCase>(
        () => _i839.AddTransaksiUseCase(gh<_i1031.TransaksiRepository>()));
    gh.lazySingleton<_i67.ExportTransaksiUseCase>(
        () => _i67.ExportTransaksiUseCase(gh<_i1031.TransaksiRepository>()));
    gh.lazySingleton<_i218.GetTransaksiDetailUseCase>(() =>
        _i218.GetTransaksiDetailUseCase(gh<_i1031.TransaksiRepository>()));
    gh.lazySingleton<_i383.GetTransaksiUseCase>(
        () => _i383.GetTransaksiUseCase(gh<_i1031.TransaksiRepository>()));
    gh.lazySingleton<_i815.HargaCubit>(() => _i815.HargaCubit(
          gh<_i1009.GetHargaUseCase>(),
          gh<_i948.AddHargaUseCase>(),
          gh<_i240.UpdateHargaUseCase>(),
          gh<_i989.DeactivateHargaUseCase>(),
          gh<_i520.ActivateHargaUseCase>(),
        ));
    gh.lazySingleton<_i474.TransaksiCubit>(() => _i474.TransaksiCubit(
          gh<_i383.GetTransaksiUseCase>(),
          gh<_i218.GetTransaksiDetailUseCase>(),
          gh<_i839.AddTransaksiUseCase>(),
          gh<_i67.ExportTransaksiUseCase>(),
        ));
    return this;
  }
}

class _$StorageModule extends _i624.StorageModule {}
