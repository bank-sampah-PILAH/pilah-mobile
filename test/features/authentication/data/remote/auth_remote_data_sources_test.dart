import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/features/authentication/data/remote/auth_remote_data_sources.dart';

class _MockNetworkService extends Mock implements NetworkService {}

void main() {
  test('a role change PATCHes onboarding/role and returns the session body',
      () async {
    final network = _MockNetworkService();
    final session = <String, dynamic>{
      'access_token': 'access-new',
      'next_step': 'complete_profile',
    };
    when(() => network.patch(
          '/api/v1/onboarding/role',
          data: {'role': 'nasabah'},
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/api/v1/onboarding/role'),
          data: session,
        ));

    final body = await AuthRemoteDataSourceImpl(network).changeRole('nasabah');

    expect(body, session);
  });

  test('restoring a session GETs auth/me and maps the user', () async {
    final network = _MockNetworkService();
    when(() => network.get('/api/v1/auth/me')).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/auth/me'),
        data: {
          'id': 'user-1',
          'nama': 'Ayu',
          'email': 'ayu@example.com',
          'role': 'nasabah',
          'state': 'complete_profile',
        },
      ),
    );

    final auth = await AuthRemoteDataSourceImpl(network).getMe();

    expect(auth.email, 'ayu@example.com');
    expect(auth.role, 'nasabah');
  });
}
