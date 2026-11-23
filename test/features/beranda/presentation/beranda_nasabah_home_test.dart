import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';

import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

import '../../../support/active_membership_support.dart';
import '../../../support/nasabah_approval_support.dart';
import '../../../support/auth_support.dart';
import '../../../support/fake_image_download.dart';
import '../../../support/stub_api.dart';

class _JadwalRepository extends Mock implements JadwalRepository {}

/// A preview repository whose home carries the given balance and activities.
class _HomeRepository extends PreviewNasabahRepository {
  _HomeRepository(this.balanceUpdatedAt, this.activities, {this.logoUrl});

  final DateTime? balanceUpdatedAt;
  final List<NasabahActivity> activities;
  final String? logoUrl;
  final asked = <String?>[];

  /// Banks the backend offers when the beranda asks without a membership,
  /// which is how the nasabah picks one from this screen.
  List<MembershipChoice> choices = const [];

  @override
  Future<NasabahBank> bank(String membershipId) async =>
      NasabahBank('Bank Sampah Melati', 'Jl. Melati', 'Depok', '08123456789',
          logoUrl: logoUrl);

  @override
  Future<NasabahHome> home({String? membershipId}) async {
    asked.add(membershipId);
    if (membershipId == null && choices.isNotEmpty) {
      throw NasabahApiException('Pilih bank sampah Anda.', choices: choices);
    }
    return NasabahHome(
      await profile(),
      membershipId ?? 'membership-1',
      await bank(''),
      NasabahBalance('12500.50', balanceUpdatedAt),
      activities,
    );
  }
}

void main() {
  late TestAuthenticationNotifier auth;
  late _JadwalRepository jadwal;

  setUp(() {
    auth = authNotifierIn(Authenticated(
      authEntity: AuthEntity(
        id: 'nasabah-1',
        name: 'Siti',
        email: 'siti@example.test',
        photoUrl: '',
        token: 'token',
        role: 'nasabah',
        nextStep: 'nasabah_dashboard',
      ),
    ));
    jadwal = _JadwalRepository();
    when(() => jadwal.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => const Right(
          JadwalPageResult(items: [], totalCount: 0, hasMore: false)),
    );
    di.registerSingleton<JadwalRepository>(jadwal);
  });

  tearDown(() async {
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
    await di.unregister<JadwalRepository>();
  });

  Future<void> pumpHome(
    WidgetTester tester,
    NasabahRepository repository, {
    Map<String, Widget Function(BuildContext, GoRouterState)> extraRoutes =
        const {},
    MemoryAppStorage? storage,
    List<NasabahMembershipEntity>? memberships,
  }) async {
    di.registerSingleton<NasabahRepository>(repository);
    final router = GoRouter(initialLocation: '/beranda', routes: [
      GoRoute(path: '/beranda', builder: (_, __) => const BerandaNasabahPage()),
      GoRoute(
        path: '/jadwal',
        builder: (_, state) => const Scaffold(body: Text('halaman jadwal')),
      ),
      GoRoute(
        path: AppLocations.history,
        builder: (_, state) => Scaffold(
            body:
                Text('riwayat ${state.uri.queryParameters['keanggotaan_id']}')),
      ),
      for (final entry in extraRoutes.entries)
        GoRoute(path: entry.key, builder: entry.value),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp.router(routerConfig: router),
      overrides: [
        // Without storage nothing is remembered, which is what every other
        // test here assumes.
        activeMembershipSelectionProvider.overrideWithValue(
          storage == null
              ? ActiveMembershipSelection.none()
              : ActiveMembershipSelection(storage),
        ),
        if (memberships != null)
          nasabahApprovalProvider.overrideWith(
            () => TestNasabahApprovalNotifier(
              initialState: NasabahApprovalLoaded(memberships),
            ),
          ),
      ],
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the bank the nasabah last chose', (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-dipilih');
    final repository = _HomeRepository(null, const []);

    await pumpHome(
      tester,
      repository,
      storage: storage,
      // The saved bank is still openable, so it survives reconciliation.
      memberships: [membershipRow('membership-dipilih')],
    );

    // Without the saved choice the first load asks for null, and the beranda
    // would call whichever bank the backend defaulted to "Aktif".
    expect(repository.asked.first, 'membership-dipilih');
  });

  testWidgets('reloads when the active bank is switched elsewhere',
      (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-dipilih');
    final repository = _HomeRepository(null, const []);

    await pumpHome(
      tester,
      repository,
      storage: storage,
      memberships: [
        membershipRow('membership-dipilih'),
        membershipRow('membership-lain'),
      ],
    );
    expect(repository.asked, ['membership-dipilih']);

    // Standing in for the switch made on the "Bank sampah saya" detail page.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BerandaNasabahPage)),
    );
    await container
        .read(activeMembershipProvider.notifier)
        .select('membership-lain');
    await tester.pumpAndSettle();

    expect(repository.asked, ['membership-dipilih', 'membership-lain']);
  });

  testWidgets(
      'a bank picked here becomes the saved active bank, and a later switch '
      'elsewhere still reloads', (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-a');
    final repository = _HomeRepository(null, const [])
      ..choices = const [MembershipChoice('membership-b', 'Mawar')];

    await pumpHome(
      tester,
      repository,
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );
    expect(repository.asked, ['membership-a']);

    // Asking for the chooser back reloads without a membership, which is what
    // makes the backend offer the banks to pick from.
    await tester.tap(find.byTooltip('Pilih ulang bank sampah'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Mawar'));
    await tester.pumpAndSettle();

    expect(repository.asked, ['membership-a', null, 'membership-b']);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BerandaNasabahPage)),
    );
    // The bank picked here is the one "Bank sampah saya" marks as active, so
    // the two screens cannot disagree about which bank is in use.
    expect(container.read(activeMembershipProvider).value, 'membership-b');
    expect(storage.values['active_membership_id:nasabah-1'], 'membership-b');

    // Standing in for a switch made afterwards on the membership detail page:
    // a pick made here must not deafen the beranda to it.
    await container
        .read(activeMembershipProvider.notifier)
        .select('membership-a');
    await tester.pumpAndSettle();

    expect(repository.asked,
        ['membership-a', null, 'membership-b', 'membership-a']);
  });

  testWidgets('follows the bank a membership refresh resolves to',
      (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-a');
    final repository = _HomeRepository(null, const []);

    await pumpHome(
      tester,
      repository,
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );
    expect(repository.asked, ['membership-a']);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BerandaNasabahPage)),
    );
    final approval = container.read(nasabahApprovalProvider.notifier)
        as TestNasabahApprovalNotifier;
    // The refresh finds the saved bank no longer openable, so the selection
    // resolves to the other one. The reload is not the first resolution, and
    // it arrives as a loading-to-data transition like every other refresh.
    approval.setStateForTest(NasabahApprovalLoaded([
      membershipRow('membership-a', dibuka: false),
      membershipRow('membership-b'),
    ]));
    await tester.pumpAndSettle();

    expect(repository.asked, ['membership-a', 'membership-b']);
    expect(container.read(activeMembershipProvider).value, 'membership-b');
  });

  // The greeting follows the clock, so each time of day is checked against a
  // fixed one and the result does not depend on when the suite runs.
  const greetings = {
    5: 'Selamat pagi',
    12: 'Selamat siang',
    16: 'Selamat sore',
    20: 'Selamat malam',
  };
  for (final entry in greetings.entries) {
    testWidgets('greets ${entry.value.toLowerCase()} at ${entry.key}:00',
        (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 10, 6, entry.key)), () async {
        await pumpHome(tester, _HomeRepository(null, const []));

        expect(find.text(entry.value), findsOneWidget);
      });
    });
  }

  testWidgets('the balance card names the latest activity and its date',
      (tester) async {
    await pumpHome(
        tester,
        _HomeRepository(null, [
          NasabahActivity(
              'a1', DateTime(2026, 9, 23, 9), 'pencairan', '5000.00'),
        ]));

    expect(find.text('Pencairan · 23/09/2026'), findsOneWidget);
  });

  testWidgets('an unrecognised activity type is shown as sent', (tester) async {
    await pumpHome(
        tester,
        _HomeRepository(null, [
          NasabahActivity('a1', DateTime(2026, 9, 23, 9), 'koreksi', '1000.00'),
        ]));

    expect(find.text('koreksi · 23/09/2026'), findsOneWidget);
  });

  testWidgets('without activity it says when the balance was updated',
      (tester) async {
    await pumpHome(tester, _HomeRepository(DateTime(2026, 9, 20, 9), const []));

    expect(find.text('Diperbarui 20/09/2026'), findsOneWidget);
  });

  testWidgets('Semua links go to the schedule and to the history',
      (tester) async {
    await pumpHome(tester, _HomeRepository(null, const []));

    await tester.tap(find.widgetWithText(TextButton, 'Semua').first);
    await tester.pumpAndSettle();
    expect(find.text('halaman jadwal'), findsOneWidget);

    // Back to the home page for the second link.
    final router = GoRouter.of(tester.element(find.text('halaman jadwal')));
    router.go('/beranda');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Semua').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Semua').last);
    await tester.pumpAndSettle();
    expect(find.text('riwayat membership-1'), findsOneWidget);
  });

  testWidgets('choosing the bank again reloads the home without a membership',
      (tester) async {
    final repository = _HomeRepository(null, const []);
    await pumpHome(tester, repository);
    expect(repository.asked, [null]);

    await tester.tap(find.byTooltip('Pilih ulang bank sampah'));
    await tester.pumpAndSettle();

    expect(repository.asked, [null, null]);
  });

  testWidgets('a stored bank logo is drawn from its URL', (tester) async {
    final debugImage = FakeImageDownload.install();
    await pumpHome(
        tester, _HomeRepository(null, const [], logoUrl: '/media/logo.png'));

    // Let the avatar start its download without racing it.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    debugImage.finish();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(avatar.foregroundImage, isA<NetworkImage>());
    expect((avatar.foregroundImage! as NetworkImage).url, isNotEmpty);
    FakeImageDownload.uninstall();
  });

  testWidgets('without a logo the membership card keeps its BS initial',
      (tester) async {
    await pumpHome(tester, _HomeRepository(null, const []));
    expect(find.text('BS'), findsOneWidget);
  });

  testWidgets('a failing schedule request is reported in its own card',
      (tester) async {
    when(() => jadwal.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Left(GeneralException(message: 'offline')),
    );
    await pumpHome(tester, _HomeRepository(null, const []));

    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('the home draws no Pengumuman section', (tester) async {
    await pumpHome(tester, _HomeRepository(null, const []));

    expect(find.text('Pengumuman'), findsNothing);
    expect(find.text('Belum ada pengumuman.'), findsNothing);
    expect(find.byKey(const ValueKey('beranda-pengumuman-baru')), findsNothing);
    expect(find.byIcon(Icons.campaign_outlined), findsNothing);
  });

  testWidgets('every activity type keeps its title in the shared list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NasabahActivityList(activities: [
          NasabahActivity('a', DateTime(2026, 9, 1), 'setoran', '1000.00'),
          NasabahActivity('b', DateTime(2026, 9, 2), 'pencairan', '500.00'),
          NasabahActivity('c', DateTime(2026, 9, 3), 'koreksi', '100.00'),
        ]),
      ),
    ));

    expect(find.text('Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.text('koreksi'), findsOneWidget);
  });

  testWidgets('opens notification history from the Nasabah home',
      (tester) async {
    final handle = tester.ensureSemantics();
    final api = StubApi();
    api.on('GET', '/api/v1/notifications/', json: {
      'count': 0,
      'next': null,
      'previous': null,
      'results': [],
    });
    di.registerSingleton<NetworkService>(api.network);
    addTearDown(() => di.unregister<NetworkService>());

    await pumpHome(tester, _HomeRepository(null, const []));

    expect(find.bySemanticsLabel('Notifikasi'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada notifikasi.'), findsOneWidget);
    expect(
      api.requests.any((request) => request.path == '/api/v1/notifications/'),
      isTrue,
    );
    handle.dispose();
  });
}
