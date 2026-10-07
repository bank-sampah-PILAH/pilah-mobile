import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pilah_mobile/core/database/secure_database.dart';
import 'package:pilah_mobile/features/authentication/data/auth_repository_impl.dart';
import 'package:pilah_mobile/features/authentication/data/local/auth_local_data_sources.dart';
import 'package:pilah_mobile/features/authentication/data/remote/auth_remote_data_sources.dart';
import 'package:pilah_mobile/features/authentication/domain/authentication_interactor.dart';

import 'stub_api.dart';

/// The real auth repository over the real data sources: HTTP stubbed, secure
/// storage replaced by the plugin's in-memory test platform.
class AuthStack {
  AuthStack(this.api, {Map<String, String> stored = const {}}) {
    FlutterSecureStorage.setMockInitialValues({...stored});
    database = const SecureDatabaseImpl();
    local = AuthLocalDataSourcesImpl(database, api.utils);
    repository =
        AuthRepositoryImpl(AuthRemoteDataSourceImpl(api.network), local);
    interactor = AuthenticationInteractor(repository);
  }

  final StubApi api;
  late final SecureDatabase database;
  late final AuthLocalDataSourcesImpl local;
  late final AuthRepositoryImpl repository;
  late final AuthenticationInteractor interactor;
}

/// A login/session payload as the API returns it.
Map<String, dynamic> authPayload({
  String? nextStep = 'dashboard',
  String role = 'pengelola',
  String? bankStatus,
}) =>
    {
      'access_token': 'access-1',
      'refresh_token': 'refresh-1',
      'token_type': 'Bearer',
      'expires_in': 3600,
      'next_step': nextStep,
      'is_new_user': false,
      'user': {
        'id': 'u1',
        'name': 'Siti Aminah',
        'email': 'siti@x.test',
        'no_hp': '+62812',
        'jenis_kelamin': 'perempuan',
        'tanggal_lahir': '1998-05-17',
        'alamat': 'Jl. Melati',
        'role': role,
        'bank_sampah_nama': 'Bank Melati',
        'bank_sampah_status': bankStatus,
      },
    };
