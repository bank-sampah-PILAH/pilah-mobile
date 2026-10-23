import '../../support/stub_api.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/features/pengumuman/data/nasabah_pengumuman_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/auth_support.dart';
import '../../support/approved_membership.dart';
import '../../support/jadwal_provider_support.dart';

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
  });

  testWidgets('unknown roles fail closed on the jadwal route', (tester) async {
    if (di.isRegistered<NasabahRepository>()) {
      di.unregister<NasabahRepository>();
    }
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    // The beranda page resolves the pengumuman section from the service
    // locator, so the stub API behind it needs the same registration.
    final pengumumanApi = StubApi();
    pengumumanApi.on('GET', '/api/v1/nasabah/me/pengumuman/beranda',
        json: {'items': [], 'unread_count': 0});
    di.registerSingleton<NasabahPengumumanRepository>(
        NasabahPengumumanRepository(pengumumanApi.network));
    addTearDown(() => di.unregister<NasabahPengumumanRepository>());
    addTearDown(() => di.unregister<NasabahRepository>());
    final approval = buildApprovedMembershipNotifier();

    final auth = TestAuthenticationNotifier(
      initialState: AuthenticationLoading(),
    );
    final requestedDates = <DateTime?>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = today.add(const Duration(days: 2));
    final dateParam = '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
    final startsAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
    ).toUtc();
    final schedule = JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: startsAt,
      selesaiPada: startsAt.add(const Duration(hours: 2)),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );
    final jadwalNotifier = TestJadwalNotifier(
      repository: UnusedJadwalRepository(),
      initialState: JadwalLoaded([schedule]),
      onLoadJadwal: (
          {bool silent = false, DateTime? date, DateTime? dateTo}) async {
        requestedDates.add(date);
      },
      onLoadCalendarDates: ({required startDate, required endDate}) async {},
      onLoadUpcomingDates: ({today}) async {},
      onLoadNextPage: () async {},
    );

    final router = AppRouterConfig.getRouter();
    router.go('${JadwalPage.route}?date=$dateParam');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jadwalProvider.overrideWith(() => jadwalNotifier),
          nasabahApprovalProvider.overrideWith(() => approval),
          authenticationProvider.overrideWith(() => auth),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            ref.listen(authenticationProvider, (_, __) {
              AppRouterConfig.notifyAuthStateChanged();
            });
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Jadwal Kegiatan'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    for (final role in <String?>[null, 'unknown-role']) {
      auth.setStateForTest(
        Authenticated(
          authEntity: AuthEntity(
            id: 'nasabah-1',
            name: 'Nasabah',
            email: 'nasabah@example.com',
            photoUrl: '',
            token: 'token',
            role: role,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Silakan masuk sebagai nasabah.'), findsOneWidget);
      expect(find.text('Jadwal Bank Sampah'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Batalkan'), findsNothing);
      expect(find.text('Terbitkan'), findsNothing);
      expect(find.text('Tandai Selesai'), findsNothing);
    }

    auth.setStateForTest(
      Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Nasabah',
          email: 'nasabah@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go('${JadwalPage.route}?date=$dateParam');
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Bank Sampah'), findsOneWidget);
    expect(find.text('Balai Warga'), findsOneWidget);
    expect(requestedDates.where((date) => date == selectedDate), hasLength(1));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Terbitkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);

    final nextDate = selectedDate.add(const Duration(days: 1));
    final nextDateParam = '${nextDate.year.toString().padLeft(4, '0')}-'
        '${nextDate.month.toString().padLeft(2, '0')}-'
        '${nextDate.day.toString().padLeft(2, '0')}';
    router.go('${JadwalPage.route}?date=$nextDateParam');
    await tester.pumpAndSettle();

    expect(
      find.text(formatJadwalDayHeading(nextDate, today: today)),
      findsOneWidget,
    );
    expect(requestedDates.where((date) => date == nextDate), hasLength(1));

    final manualDate = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day == 15 ? 16 : 15,
    );
    await tester.tap(find.byKey(const ValueKey('jadwal-calendar-toggle')));
    await tester.pumpAndSettle();
    final manualDateCell = find.byKey(ValueKey(
      'jadwal-date-${manualDate.year}-${manualDate.month}-${manualDate.day}',
    ));
    await tester.ensureVisible(manualDateCell);
    await tester.tap(manualDateCell);
    await tester.pumpAndSettle();
    expect(
      find.text(formatJadwalDayHeading(manualDate, today: today)),
      findsOneWidget,
    );

    auth.setStateForTest(
      Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Nasabah',
          email: 'nasabah@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );
    await tester.pumpAndSettle();
    // An auth-state refresh must not erase a date selected inside the page
    // when the route itself did not change.
    expect(
      find.text(formatJadwalDayHeading(manualDate, today: today)),
      findsOneWidget,
    );
    expect(requestedDates.where((date) => date == manualDate), hasLength(1));
    expect(requestedDates.where((date) => date == nextDate), hasLength(1));
  });
}
