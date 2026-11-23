import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_chip.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
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
    Size size = const Size(390, 844),
    TestNasabahApprovalNotifier? approval,
    AuthEntity owner = _owner,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = TestAuthenticationNotifier(
      initialState: Authenticated(authEntity: owner),
    );
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      activeMembershipSelectionProvider.overrideWithValue(
        ActiveMembershipSelection(storage),
      ),
      activeMembershipUserIdProvider.overrideWithValue('nasabah-1'),
      nasabahApprovalProvider.overrideWith(
        () =>
            approval ??
            TestNasabahApprovalNotifier(
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
          owner: owner,
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

  testWidgets('search filters followed and history by bank name',
      (tester) async {
    final pending = membershipRow(
      'pending-a',
      nama: 'Anggrek',
      status: MembershipStatus.pending,
    );
    final rejected = membershipRow(
      'rejected-c',
      nama: 'Cempaka',
      status: MembershipStatus.rejected,
    );
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final (container, _) = await pumpPage(
      tester,
      memberships: [bankA, pending, rejected],
      storage: storage,
    );
    final search = find.byType(TextField);

    await tester.enterText(search, '  BANK A  ');
    await tester.pumpAndSettle();
    expect(find.text('Bank A').hitTestable(), findsOneWidget);
    expect(find.text('Anggrek').hitTestable(), findsNothing);
    await tester.tap(find.text('Riwayat pengajuan'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, '  BANK A  ');
    expect(find.text('Bank A').hitTestable(), findsOneWidget);
    expect(find.text('Anggrek').hitTestable(), findsNothing);

    await tester.enterText(search, 'a');
    await tester.pumpAndSettle();
    expect(find.text('Anggrek').hitTestable(), findsOneWidget);
    expect(find.text('Cempaka').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Bank Diikuti'));
    await tester.pumpAndSettle();
    expect(find.text('Bank A').hitTestable(), findsOneWidget);
    expect(find.text('Anggrek').hitTestable(), findsNothing);
    await tester.enterText(search, 'no matching bank');
    await tester.pumpAndSettle();
    expect(find.text('Tidak ada bank diikuti yang cocok'), findsOneWidget);
    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
    expect(container.read(activeMembershipProvider).value, bankA.id);
  });

  testWidgets('search clear and no-match differ from true empty state',
      (tester) async {
    await pumpPage(tester, memberships: [], storage: MemoryAppStorage());
    final search = find.byType(TextField);

    expect(find.text('Belum ada bank yang diikuti'), findsOneWidget);
    await tester.enterText(search, 'bank');
    await tester.pumpAndSettle();
    expect(find.text('Belum ada bank yang diikuti'), findsOneWidget);
    expect(find.text('Tidak ada bank diikuti yang cocok'), findsNothing);
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada bank yang diikuti'), findsOneWidget);
    await tester.tap(find.text('Riwayat pengajuan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat pengajuan'), findsOneWidget);
    await tester.enterText(search, 'bank');
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat pengajuan'), findsOneWidget);
    expect(find.text('Tidak ada pengajuan yang cocok'), findsNothing);
  });

  testWidgets('history status filter combines with search and resets',
      (tester) async {
    final pending = membershipRow(
      'pending-a',
      nama: 'Anggrek',
      status: MembershipStatus.pending,
    );
    final rejected = membershipRow(
      'rejected-c',
      nama: 'Cempaka',
      status: MembershipStatus.rejected,
    );
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final (container, _) = await pumpPage(
      tester,
      memberships: [bankA, pending, rejected],
      storage: storage,
    );
    final search = find.byType(TextField);

    await tester.tap(find.text('Riwayat pengajuan'));
    await tester.pumpAndSettle();
    await tester.enterText(search, 'a');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppChip, 'Ditolak'));
    await tester.pumpAndSettle();
    expect(find.text('Cempaka').hitTestable(), findsOneWidget);
    expect(find.text('Anggrek').hitTestable(), findsNothing);

    await tester.tap(find.text('Bank Diikuti'));
    await tester.pumpAndSettle();
    expect(find.text('Bank A').hitTestable(), findsOneWidget);
    expect(find.text('Anggrek').hitTestable(), findsNothing);
    await tester.tap(find.text('Riwayat pengajuan'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppChip>(find.widgetWithText(AppChip, 'Ditolak')).selected,
      isTrue,
    );

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(
      tester.widget<AppChip>(find.widgetWithText(AppChip, 'Ditolak')).selected,
      isTrue,
    );
    expect(find.text('Cempaka').hitTestable(), findsOneWidget);
    expect(find.text('Anggrek').hitTestable(), findsNothing);

    await tester.tap(find.text('Reset pencarian dan filter'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(find.text('Bank A'), findsOneWidget);
    expect(find.text('Anggrek'), findsOneWidget);
    expect(find.text('Cempaka'), findsOneWidget);
    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
    expect(container.read(activeMembershipProvider).value, bankA.id);
  });

  testWidgets('shows a load failure and retries the memberships',
      (tester) async {
    final approval = _FailOnceApproval([bankA]);
    await pumpPage(tester,
        memberships: [bankA], storage: MemoryAppStorage(), approval: approval);

    expect(find.text('Gagal Memuat Data'), findsOneWidget);
    expect(find.text('Coba periksa koneksi Anda.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Bank A'), findsOneWidget);
  });

  testWidgets('shows the provider error and an empty history after retry',
      (tester) async {
    final approval =
        _FailOnceApproval(const [], errorMessage: 'Tidak terhubung');
    await pumpPage(tester,
        history: true,
        memberships: [],
        storage: MemoryAppStorage(),
        approval: approval);

    expect(find.text('Tidak terhubung'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat pengajuan'), findsOneWidget);
    expect(find.text('Ajukan bank baru'), findsNothing);
    await tester.tap(find.text('Bank Diikuti'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada bank yang diikuti'), findsOneWidget);
  });

  testWidgets('active bank sorts first and wide detail closes its chevron',
      (tester) async {
    await pumpPage(
      tester,
      size: const Size(1440, 900),
      memberships: [bankA, bankB],
      storage: MemoryAppStorage()
        ..values['active_membership_id:nasabah-1'] = bankB.id,
    );

    expect(tester.getTopLeft(find.text('Bank B')).dy,
        lessThan(tester.getTopLeft(find.text('Bank A')).dy));
    await tester.tap(find.text('Bank B'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Jadikan bank aktif'), findsNothing);
    expect(
        tester
            .widgetList<AnimatedRotation>(
                find.byType(AnimatedRotation, skipOffstage: false))
            .map((rotation) => rotation.turns),
        contains(.5));
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(
        tester
            .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
            .map((rotation) => rotation.turns),
        everyElement(0));
  });

  testWidgets('successful history detail return reloads in place',
      (tester) async {
    final (container, _) = await pumpPage(tester,
        history: true, memberships: [bankA], storage: MemoryAppStorage());
    final approval = container.read(nasabahApprovalProvider.notifier)
        as TestNasabahApprovalNotifier;
    approval.loadCalls.clear();
    await tester.tap(find.text('Bank A'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Persetujuan'), findsOneWidget);

    // A successful appeal returns true from the detail overlay.
    Navigator.of(tester.element(find.text('Riwayat Persetujuan'))).pop(true);
    await tester.pumpAndSettle();
    expect(approval.loadCalls, [true]);
    expect(find.text('Riwayat pengajuan'), findsOneWidget);
  });

  testWidgets('same-account refresh keeps the page and account change hides it',
      (tester) async {
    final (container, _) = await pumpPage(tester,
        memberships: [bankA], storage: MemoryAppStorage());
    final auth = container.read(authenticationProvider.notifier)
        as TestAuthenticationNotifier;
    auth.setStateForTest(Authenticated(
        authEntity: const AuthEntity(
      id: 'nasabah-1',
      name: 'Siti',
      email: 'SITI@example.test',
      photoUrl: '',
      token: '',
      role: 'nasabah',
    )));
    await tester.pumpAndSettle();
    expect(find.text('Bank A'), findsOneWidget);
    auth.setStateForTest(Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('Bank A'), findsNothing);
    expect(find.textContaining('Sesi berubah'), findsOneWidget);
  });

  testWidgets('session without an ID matches normalized account email',
      (tester) async {
    final (container, _) = await pumpPage(
      tester,
      memberships: [bankA],
      storage: MemoryAppStorage(),
      owner: const AuthEntity(
        name: 'Siti',
        email: '  SITI@example.test ',
        photoUrl: '',
        token: 'token-1',
        role: 'nasabah',
      ),
    );
    final auth = container.read(authenticationProvider.notifier)
        as TestAuthenticationNotifier;
    auth.setStateForTest(Authenticated(authEntity: _owner));
    await tester.pumpAndSettle();
    expect(find.text('Bank A'), findsOneWidget);
  });

  testWidgets('an open detail cannot reload after logout', (tester) async {
    final (container, _) = await pumpPage(tester,
        memberships: [bankA], storage: MemoryAppStorage());
    await tester.tap(find.text('Bank A'));
    await tester.pumpAndSettle();
    final detail = tester.state<NasabahResourceState<NasabahBank>>(
      find.byType(NasabahResource<NasabahBank>),
    );
    final auth = container.read(authenticationProvider.notifier)
        as TestAuthenticationNotifier;
    auth.setStateForTest(Unauthenticated());
    await expectLater(detail.reload(), throwsStateError);
    await tester.pumpAndSettle();
    expect(find.text('Sesi berubah. Tutup dan masuk kembali.'), findsOneWidget);
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

class _FailOnceApproval extends TestNasabahApprovalNotifier {
  _FailOnceApproval(List<NasabahMembershipEntity> memberships,
      {this.errorMessage})
      : super(initialState: NasabahApprovalLoaded(memberships));

  final String? errorMessage;
  bool _failed = false;

  @override
  Future<void> load({bool silent = false}) async {
    if (_failed) return super.load(silent: silent);
    _failed = true;
    final message = errorMessage;
    if (message == null) throw StateError('Test connection failure');
    setStateForTest(NasabahApprovalError(message));
  }
}
