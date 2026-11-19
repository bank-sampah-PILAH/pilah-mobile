import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/nasabah_jadwal_detail_page.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../../../support/auth_support.dart';
import '../../../../support/stub_api.dart';

void main() {
  testWidgets(
      'an unavailable schedule link explains that access is unavailable',
      (tester) async {
    final api = StubApi();
    api.on('GET', '/api/v1/jadwal/other-bank',
        status: 404, json: {'detail': 'Not found.'});
    di.registerSingleton<JadwalRepository>(
        JadwalRepositoryImpl(JadwalRemoteDataSourceImpl(api.network)));
    addTearDown(di.reset);
    final auth = authNotifierIn(Authenticated(
        authEntity: const AuthEntity(
      id: 'customer',
      name: 'Siti',
      email: 'siti@example.test',
      photoUrl: '',
      token: 'token',
      role: 'nasabah',
    )));
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      const MaterialApp(home: NasabahJadwalDetailPage(id: 'other-bank')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal tidak tersedia.'), findsOneWidget);
    expect(find.text('Lokasi'), findsNothing);
    expect(find.text('Not found.'), findsNothing);
    expect(api.requests.single.method, 'GET');
  });
}
