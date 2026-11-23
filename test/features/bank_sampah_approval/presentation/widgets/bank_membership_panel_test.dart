import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/bank_membership_panel.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_nasabah_screen.dart';

import '../../../../support/active_membership_support.dart';
import '../../../../support/auth_support.dart';
import '../../../../support/nasabah_approval_support.dart';

const _owner = AuthEntity(
  id: 'nasabah-1',
  name: 'Siti',
  email: 'siti@example.test',
  photoUrl: '',
  token: 'token-1',
  role: 'nasabah',
);

void main() {
  setUp(() =>
      di.registerSingleton<NasabahRepository>(PreviewNasabahRepository()));
  tearDown(() => di.reset());

  Future<(ProviderContainer, GoRouter)> pumpPage(
    WidgetTester tester, {
    required List<NasabahMembershipEntity> memberships,
    required MemoryAppStorage storage,
    bool history = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = TestAuthenticationNotifier(
      initialState: Authenticated(authEntity: _owner),
    );
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      activeMembershipSelectionProvider.overrideWithValue(
        ActiveMembershipSelection(storage),
      ),
      activeMembershipUserIdProvider.overrideWithValue('nasabah-1'),
      nasabahApprovalProvider.overrideWith(
        () => TestNasabahApprovalNotifier(
          initialState: NasabahApprovalLoaded(memberships),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push(Uri(
              path: '/approval-bank-sampah',
              queryParameters: history ? {'tab': 'history'} : null,
            ).toString()),
            child: const Text('Buka bank saya'),
          ),
        ),
      ),
      GoRoute(
        path: '/approval-bank-sampah',
        builder: (context, state) => BankMembershipPanel(
          owner: _owner,
          scrollToHistory: state.uri.queryParameters['tab'] == 'history',
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const Scaffold(body: Text('Beranda')),
      ),
      GoRoute(
        path: RegisterNasabahScreen.additionalRoute,
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Kirim pengajuan'),
          ),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka bank saya'));
    await tester.pumpAndSettle();
    return (container, router);
  }

  final bankA = membershipRow('membership-a', nama: 'Bank A');
  final bankB = membershipRow('membership-b', nama: 'Bank B');

  testWidgets('opens routable page defaulted to Bank Diikuti', (tester) async {
    await pumpPage(
      tester,
      memberships: [bankA],
      storage: MemoryAppStorage()
        ..values['active_membership_id:nasabah-1'] = bankA.id,
    );

    expect(find.text('Bank sampah saya'), findsOneWidget);
    expect(find.text('Bank Diikuti'), findsOneWidget);
    expect(find.text('Riwayat pengajuan'), findsOneWidget);
    expect(find.text('Bank A'), findsOneWidget);
    expect(find.text('Ajukan bank baru'), findsNothing);
  });

  testWidgets('verification entry opens directly on application history',
      (tester) async {
    await pumpPage(
      tester,
      history: true,
      memberships: [
        membershipRow(
          'pending',
          nama: 'Bank Menunggu',
          status: MembershipStatus.pending,
        ),
      ],
      storage: MemoryAppStorage(),
    );

    expect(find.text('Bank Menunggu'), findsOneWidget);
    expect(find.text('Belum ada bank yang diikuti'), findsNothing);
    expect(find.text('Ajukan bank baru'), findsOneWidget);
  });

  testWidgets('only the explicit eligible action changes active bank',
      (tester) async {
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final (container, _) = await pumpPage(
      tester,
      memberships: [bankA, bankB],
      storage: storage,
    );

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Jadikan bank aktif'), findsNothing);
    await tester.tap(find.text('Bank B'));
    await tester.pumpAndSettle();
    expect(find.text('Jadikan bank aktif'), findsOneWidget);
    await tester.tap(find.text('Jadikan bank aktif'));
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:nasabah-1'], bankB.id);
    expect(container.read(activeMembershipProvider).value, bankB.id);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('failed active-bank save keeps prior bank and offers retry',
      (tester) async {
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final (container, _) = await pumpPage(
      tester,
      memberships: [bankA, bankB],
      storage: storage,
    );
    storage.putFailure = StateError('storage unavailable');

    await tester.tap(find.text('Bank B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadikan bank aktif'));
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
    expect(container.read(activeMembershipProvider).value, bankA.id);
    expect(find.text('Pilihan belum tersimpan. Bank aktif tidak berubah.'),
        findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('unavailable approved membership stays visible and inert',
      (tester) async {
    final unavailable = membershipRow(
      'offline',
      nama: 'Bank Tidak Tersedia',
      dibuka: false,
    );
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final (container, _) = await pumpPage(
      tester,
      memberships: [bankA, unavailable],
      storage: storage,
    );

    expect(find.text('Tidak tersedia'), findsOneWidget);
    expect(find.text('Bank Tidak Tersedia'), findsOneWidget);
    expect(find.text('Jadikan bank aktif'), findsNothing);
    await tester.tap(find.text('Bank Tidak Tersedia'));
    await tester.pumpAndSettle();
    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
    expect(container.read(activeMembershipProvider).value, bankA.id);
  });

  testWidgets('successful additional application returns to history',
      (tester) async {
    final (container, _) = await pumpPage(
      tester,
      history: true,
      memberships: [bankA],
      storage: MemoryAppStorage()
        ..values['active_membership_id:nasabah-1'] = bankA.id,
    );
    final notifier = container.read(nasabahApprovalProvider.notifier)
        as TestNasabahApprovalNotifier;
    notifier.loadCalls.clear();

    await tester.tap(find.text('Ajukan bank baru'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kirim pengajuan'));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [true]);
    expect(find.text('Riwayat pengajuan'), findsOneWidget);
    expect(find.text('Bank A'), findsOneWidget);
    expect(container.read(activeMembershipProvider).value, bankA.id);
  });
}
