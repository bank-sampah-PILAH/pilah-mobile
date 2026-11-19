import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:pilah_mobile/features/jadwal/data/models/jadwal_model.dart';
import 'package:pilah_mobile/features/jadwal/data/repositories/jadwal_repository_impl.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/states/jadwal_state.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/profile/presentation/providers/profile_provider.dart';
import '../../support/approved_membership.dart';
import '../../support/auth_support.dart';
import '../../support/jadwal_provider_support.dart';
import '../../support/stub_api.dart';
import '../../support/profile_support.dart';

void main() {
  testWidgets('Nasabah opens read-only schedule details and returns to the agenda',
      (tester) async {
    final day = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    final schedule = JadwalEntity(
      id: 'schedule-1',
      bankSampahId: 'bank',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime(day.year, day.month, day.day, 9).toUtc(),
      selesaiPada: DateTime(day.year, day.month, day.day, 11).toUtc(),
      lokasi: 'Balai Warga',
      keterangan: 'Bawa sampah yang sudah dipilah.',
      status: 'diterbitkan',
    );
    final api = StubApi();
    api.on('GET', '/api/v1/jadwal/schedule-1', json: {
      ...JadwalModel.fromEntity(schedule).toJson(),
      'id': schedule.id,
      'bank_sampah': schedule.bankSampahId,
      'status': schedule.status,
    });
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
    di.registerSingleton<JadwalRepository>(
        JadwalRepositoryImpl(JadwalRemoteDataSourceImpl(api.network)));
    addTearDown(() async {
      await di.reset();
    });
    final auth = authNotifierIn(Authenticated(
      authEntity: const AuthEntity(
        id: 'customer', name: 'Siti', email: 'siti@example.test',
        photoUrl: '', token: 'token', role: 'nasabah', nextStep: 'dashboard',
      ),
    ));
    final notifier = TestJadwalNotifier(
      repository: UnusedJadwalRepository(),
      initialState: JadwalLoaded([schedule], totalCount: 1),
    );
    final router = AppRouterConfig.getRouter();
    addTearDown(router.dispose);
    final date = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    router.go('/jadwal?date=$date');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authenticationProvider.overrideWith(() => auth),
        nasabahApprovalProvider.overrideWith(buildApprovedMembershipNotifier),
        jadwalProvider.overrideWith(() => notifier),
        profileProvider.overrideWith(SilentProfileNotifier.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Balai Warga'));
    await tester.tap(find.text('Balai Warga'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Jadwal'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path,
        '/jadwal/schedule-1');
    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.text('Bawa sampah yang sudah dipilah.'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.text('Ubah Jadwal'), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(api.requests.single.path, '/api/v1/jadwal/schedule-1');

    router.pop();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.queryParameters['date'], date);
    expect(find.text('Jadwal Bank Sampah'), findsOneWidget);
  });
}
