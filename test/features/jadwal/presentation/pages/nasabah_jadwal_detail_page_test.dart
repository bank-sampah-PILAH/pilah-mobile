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
  testWidgets('a schedule spanning midnight shows its end date',
      (tester) async {
    final api = StubApi();
    api.on('GET', '/api/v1/jadwal/overnight', json: {
      'id': 'overnight',
      'bank_sampah_id': 'bank',
      'jenis_kegiatan': 'penimbangan',
      'status': 'diterbitkan',
      'mulai_pada': DateTime(2026, 11, 20, 23).toUtc().toIso8601String(),
      'selesai_pada': DateTime(2026, 11, 21, 1).toUtc().toIso8601String(),
      'lokasi': 'Balai Warga',
    });
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
      const MaterialApp(home: NasabahJadwalDetailPage(id: 'overnight')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('20/11/2026'), findsOneWidget);
    expect(find.text('21/11/2026'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
  });

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
