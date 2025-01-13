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
import '../features/profile/domain/repository/profile_repository.dart' as _i928;
import 'secure_storage.dart' as _i897;

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
    gh.factory<_i897.SecureStorage>(() => _i897.SecureStorage());
    gh.factory<_i119.AppEnvironment>(
      () => _i119.DevEnvironment(),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i124.SecureDatabase>(
        () => _i124.SecureDatabaseImpl(gh<_i897.SecureStorage>()));
    gh.lazySingleton<_i1024.ProfileLocalDataSources>(
        () => _i1024.ProfileLocalDataSourcesImpl(gh<_i124.SecureDatabase>()));
    gh.lazySingleton<_i981.AuthLocalDataSources>(
        () => _i981.AuthLocalDataSourcesImpl(gh<_i124.SecureDatabase>()));
    gh.factory<_i119.AppEnvironment>(
      () => _i119.ProdEnvironment(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i936.NetworkUtils>(
        () => _i936.NetworkUtils(gh<_i124.SecureDatabase>()));
    gh.lazySingleton<_i941.NetworkService>(() => _i941.NetworkService(
          environment: gh<_i119.AppEnvironment>(),
          networkUtils: gh<_i936.NetworkUtils>(),
        ));
    gh.lazySingleton<_i622.ProfileRemoteDataSources>(
        () => _i622.ProfileRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i24.AuthRemoteDataSources>(
        () => _i24.AuthRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i174.ProductRemoteDataSources>(
        () => _i174.ProductRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i888.AuthRepository>(() => _i493.AuthRepositoryImpl(
          gh<_i24.AuthRemoteDataSources>(),
          gh<_i981.AuthLocalDataSources>(),
        ));
    gh.lazySingleton<_i128.ProductRepository>(() =>
        _i162.ProductRepositoryImpl(gh<_i174.ProductRemoteDataSources>()));
    gh.lazySingleton<_i60.ProductUseCases>(
        () => _i283.ProductInteractor(gh<_i128.ProductRepository>()));
    gh.lazySingleton<_i438.OnboardingRemoteDataSources>(
        () => _i438.OnboardingRemoteDataSourceImpl(gh<_i941.NetworkService>()));
    gh.lazySingleton<_i928.ProfileRepository>(
        () => _i1030.ProfileRepositoryImpl(
              gh<_i622.ProfileRemoteDataSources>(),
              gh<_i1024.ProfileLocalDataSources>(),
            ));
    gh.lazySingleton<_i998.OnboardingRepository>(() =>
        _i255.OnboardingRepositoryImpl(
            gh<_i438.OnboardingRemoteDataSources>()));
    gh.factory<_i513.ProductHomeBloc>(
        () => _i513.ProductHomeBloc(gh<_i60.ProductUseCases>()));
    gh.lazySingleton<_i1022.OnboardingUseCases>(
        () => _i698.OnboardingInteractor(gh<_i998.OnboardingRepository>()));
    gh.lazySingleton<_i521.AuthenticationUseCases>(
        () => _i56.AuthenticationInteractor(gh<_i888.AuthRepository>()));
    gh.factory<_i960.AuthenticationBloc>(
        () => _i960.AuthenticationBloc(gh<_i521.AuthenticationUseCases>()));
    gh.factory<_i221.OnboardingBloc>(
        () => _i221.OnboardingBloc(gh<_i1022.OnboardingUseCases>()));
    return this;
  }
}
