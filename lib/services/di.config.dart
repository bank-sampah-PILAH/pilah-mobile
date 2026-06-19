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
import '../features/authentication/presentation/blocs/authentication_bloc.dart'
    as _i960;
import '../features/dashboard/presentation/cubit/dashboard_cubit.dart' as _i932;
import '../features/harga/data/datasources/harga_local_data_source.dart'
    as _i112;
import '../features/harga/data/repositories/harga_repository_impl.dart'
    as _i922;
import '../features/harga/domain/repositories/harga_repository.dart' as _i40;
import '../features/harga/domain/use_cases/add_harga_usecase.dart' as _i948;
import '../features/harga/domain/use_cases/deactivate_harga_usecase.dart'
    as _i989;
import '../features/harga/domain/use_cases/get_harga_usecase.dart' as _i1009;
import '../features/harga/domain/use_cases/update_harga_usecase.dart' as _i240;
import '../features/harga/presentation/cubit/harga_cubit.dart' as _i815;
import '../features/nasabah/data/datasources/nasabah_local_data_source.dart'
    as _i469;
import '../features/nasabah/data/repositories/nasabah_repository_impl.dart'
    as _i1026;
import '../features/nasabah/domain/repositories/nasabah_repository.dart'
    as _i127;
import '../features/nasabah/domain/use_cases/activate_nasabah_usecase.dart'
    as _i449;
import '../features/nasabah/domain/use_cases/deactivate_nasabah_usecase.dart'
    as _i850;
import '../features/nasabah/domain/use_cases/get_nasabah_usecase.dart' as _i789;
import '../features/nasabah/presentation/cubit/nasabah_cubit.dart' as _i958;
import '../features/onboarding/data/onboarding_repository_impl.dart' as _i255;
import '../features/onboarding/data/remote/onboarding_remote_data_sources.dart'
    as _i438;
import '../features/onboarding/domain/authentication_interactor.dart' as _i698;
import '../features/onboarding/domain/repository/onboarding_repository.dart'
    as _i998;
import '../features/onboarding/domain/use_cases/onboarding_use_cases.dart'
    as _i1022;
import '../features/onboarding/presentation/blocs/onboarding_bloc.dart'
    as _i221;
import '../features/product/data/product_repository_impl.dart' as _i162;
import '../features/product/data/remote/product_remote_data_sources.dart'
    as _i174;
import '../features/product/domain/product_interactor.dart' as _i283;
import '../features/product/domain/repository/product_repository.dart' as _i128;
import '../features/product/domain/use_cases/product_use_cases.dart' as _i60;
import '../features/product/presentation/home/blocs/product_home_bloc.dart'
    as _i513;
import '../features/profile/data/local/profile_local_data_sources.dart'
    as _i1024;
import '../features/profile/data/profile_repository_impl.dart' as _i1030;
import '../features/profile/data/remote/profile_remote_data_sources.dart'
    as _i622;
import '../features/profile/domain/profile_interactor.dart' as _i40;
import '../features/profile/domain/repository/profile_repository.dart' as _i928;
import '../features/profile/domain/use_cases/profile_use_cases.dart' as _i483;
import '../features/profile/presentation/blocs/authentication_bloc.dart'
    as _i957;
import '../features/transaksi/data/datasources/transaksi_local_data_source.dart'
    as _i430;
import '../features/transaksi/data/repositories/transaksi_repository_impl.dart'
    as _i1041;
import '../features/transaksi/domain/repositories/transaksi_repository.dart'
    as _i1031;
import '../features/transaksi/domain/use_cases/add_transaksi_usecase.dart'
    as _i839;
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
    gh.lazySingleton<_i430.TransaksiLocalDataSource>(
        () => _i430.TransaksiLocalDataSourceImpl());
    gh.lazySingleton<_i469.NasabahLocalDataSource>(
        () => _i469.NasabahLocalDataSourceImpl());
    gh.lazySingleton<_i124.SecureDatabase>(
        () => const _i124.SecureDatabaseImpl());
    gh.lazySingleton<_i112.HargaLocalDataSource>(
        () => _i112.HargaLocalDataSourceImpl());
    gh.lazySingleton<_i1031.TransaksiRepository>(() =>
        _i1041.TransaksiRepositoryImpl(gh<_i430.TransaksiLocalDataSource>()));
    gh.lazySingleton<_i981.AuthLocalDataSources>(
        () => _i981.AuthLocalDataSourcesImpl(gh<_i124.SecureDatabase>()));
    gh.lazySingleton<_i40.HargaRepository>(
        () => _i922.HargaRepositoryImpl(gh<_i112.HargaLocalDataSource>()));
    gh.lazySingleton<_i127.NasabahRepository>(
        () => _i1026.NasabahRepositoryImpl(gh<_i469.NasabahLocalDataSource>()));
    gh.factory<_i119.AppEnvironment>(
      () => _i119.ProdEnvironment(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i839.AddTransaksiUseCase>(
        () => _i839.AddTransaksiUseCase(gh<_i1031.TransaksiRepository>()));
    gh.lazySingleton<_i383.GetTransaksiUseCase>(
        () => _i383.GetTransaksiUseCase(gh<_i1031.TransaksiRepository>()));
    gh.lazySingleton<_i936.NetworkUtils>(
        () => _i936.NetworkUtils(gh<_i124.SecureDatabase>()));
    gh.lazySingleton<_i1024.ProfileLocalDataSources>(
        () => _i1024.ProfileLocalDataSourcesImpl(gh<_i124.SecureDatabase>()));
    gh.lazySingleton<_i449.ActivateNasabahUseCase>(
        () => _i449.ActivateNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i850.DeactivateNasabahUseCase>(
        () => _i850.DeactivateNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.lazySingleton<_i789.GetNasabahUseCase>(
        () => _i789.GetNasabahUseCase(gh<_i127.NasabahRepository>()));
    gh.factory<_i474.TransaksiCubit>(() => _i474.TransaksiCubit(
          gh<_i383.GetTransaksiUseCase>(),
          gh<_i839.AddTransaksiUseCase>(),
        ));
    gh.lazySingleton<_i948.AddHargaUseCase>(
        () => _i948.AddHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i989.DeactivateHargaUseCase>(
        () => _i989.DeactivateHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i1009.GetHargaUseCase>(
        () => _i1009.GetHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i240.UpdateHargaUseCase>(
        () => _i240.UpdateHargaUseCase(gh<_i40.HargaRepository>()));
    gh.lazySingleton<_i941.NetworkService>(() => _i941.NetworkService(
          environment: gh<_i119.AppEnvironment>(),
          networkUtils: gh<_i936.NetworkUtils>(),
        ));
    gh.factory<_i958.NasabahCubit>(() => _i958.NasabahCubit(
          gh<_i789.GetNasabahUseCase>(),
          gh<_i449.ActivateNasabahUseCase>(),
          gh<_i850.DeactivateNasabahUseCase>(),
        ));
    gh.lazySingleton<_i174.ProductRemoteDataSources>(
        () => _i174.ProductRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i622.ProfileRemoteDataSources>(
        () => _i622.ProfileRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i438.OnboardingRemoteDataSources>(
        () => _i438.OnboardingRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i24.AuthRemoteDataSources>(
        () => _i24.AuthRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.factory<_i815.HargaCubit>(() => _i815.HargaCubit(
          gh<_i1009.GetHargaUseCase>(),
          gh<_i948.AddHargaUseCase>(),
          gh<_i240.UpdateHargaUseCase>(),
          gh<_i989.DeactivateHargaUseCase>(),
        ));
    gh.lazySingleton<_i888.AuthRepository>(() => _i493.AuthRepositoryImpl(
          gh<_i24.AuthRemoteDataSources>(),
          gh<_i981.AuthLocalDataSources>(),
        ));
    gh.lazySingleton<_i998.OnboardingRepository>(() =>
        _i255.OnboardingRepositoryImpl(
            gh<_i438.OnboardingRemoteDataSources>()));
    gh.lazySingleton<_i128.ProductRepository>(() =>
        _i162.ProductRepositoryImpl(gh<_i174.ProductRemoteDataSources>()));
    gh.lazySingleton<_i928.ProfileRepository>(
        () => _i1030.ProfileRepositoryImpl(
              gh<_i622.ProfileRemoteDataSources>(),
              gh<_i1024.ProfileLocalDataSources>(),
            ));
    gh.factory<_i932.DashboardCubit>(() => _i932.DashboardCubit(
          gh<_i958.NasabahCubit>(),
          gh<_i474.TransaksiCubit>(),
        ));
    gh.lazySingleton<_i521.AuthenticationUseCases>(
        () => _i56.AuthenticationInteractor(gh<_i888.AuthRepository>()));
    gh.lazySingleton<_i483.ProfileUseCases>(
        () => _i40.ProfileInteractor(gh<_i928.ProfileRepository>()));
    gh.lazySingleton<_i1022.OnboardingUseCases>(
        () => _i698.OnboardingInteractor(gh<_i998.OnboardingRepository>()));
    gh.factory<_i221.OnboardingBloc>(
        () => _i221.OnboardingBloc(gh<_i1022.OnboardingUseCases>()));
    gh.factory<_i957.ProfileBloc>(
        () => _i957.ProfileBloc(gh<_i483.ProfileUseCases>()));
    gh.factory<_i960.AuthenticationBloc>(
        () => _i960.AuthenticationBloc(gh<_i521.AuthenticationUseCases>()));
    gh.lazySingleton<_i60.ProductUseCases>(
        () => _i283.ProductInteractor(gh<_i128.ProductRepository>()));
    gh.factory<_i513.ProductHomeBloc>(
        () => _i513.ProductHomeBloc(gh<_i60.ProductUseCases>()));
    return this;
  }
}

class _$StorageModule extends _i624.StorageModule {}
