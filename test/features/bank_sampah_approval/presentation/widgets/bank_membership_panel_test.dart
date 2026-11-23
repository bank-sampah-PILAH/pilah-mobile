import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/app_sheet_container.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';
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
  Future<ProviderContainer> pumpPanel(
    WidgetTester tester, {
    required List<NasabahMembershipEntity> memberships,
    required MemoryAppStorage storage,
    bool scrollToHistory = false,
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
            onPressed: () => showBankMembershipPanel(
              context,
              owner: _owner,
              scrollToHistory: scrollToHistory,
              onOpenActiveBank: (context, _) {},
            ),
            child: const Text('Buka bank saya'),
          ),
        ),
      ),
      GoRoute(
        path: ApprovalBankSampahDetailPage.route,
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop(false),
            child: Text(
              'detail ${(state.extra! as NasabahMembershipEntity).bankSampahNama}',
            ),
          ),
        ),
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
    return container;
  }

  final bankA = membershipRow('membership-a', nama: 'Bank A');
  final bankB = membershipRow('membership-b', nama: 'Bank B');

  testWidgets('one panel shows followed banks above application history',
      (tester) async {
    await pumpPanel(
      tester,
      memberships: [
        bankA,
        membershipRow(
          'pending',
          nama: 'Bank Menunggu',
          status: MembershipStatus.pending,
          dibuka: false,
        ),
        membershipRow(
          'rejected',
          nama: 'Bank Ditolak',
          status: MembershipStatus.rejected,
          dibuka: false,
        ),
      ],
      storage: MemoryAppStorage()
        ..values['active_membership_id:nasabah-1'] = bankA.id,
    );

    final followed = tester.getTopLeft(find.text('Bank diikuti')).dy;
    final history = tester.getTopLeft(find.text('Riwayat pengajuan')).dy;
    expect(followed, lessThan(history));
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('Bank A'), findsNWidgets(2));
    expect(find.text('Bank Menunggu'), findsOneWidget);
    expect(find.text('Bank Ditolak'), findsOneWidget);
    expect(find.text('Disetujui'), findsNWidgets(2));
    expect(find.text('Menunggu'), findsOneWidget);
  });

  testWidgets('verification history opens without an empty followed section',
      (tester) async {
    await pumpPanel(
      tester,
      scrollToHistory: true,
      memberships: [
        membershipRow(
          'pending',
          nama: 'Bank Menunggu',
          status: MembershipStatus.pending,
          dibuka: false,
        ),
      ],
      storage: MemoryAppStorage(),
    );

    expect(find.text('Bank diikuti'), findsNothing);
    expect(find.text('Belum ada bank yang diikuti'), findsNothing);
    expect(find.text('Riwayat pengajuan'), findsOneWidget);
    expect(find.text('Bank Menunggu'), findsOneWidget);
  });

  testWidgets('switching banks saves the choice and closes the panel',
      (tester) async {
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final container = await pumpPanel(
      tester,
      memberships: [bankA, bankB],
      storage: storage,
    );

    expect(find.text('Aktif'), findsOneWidget);
    expect(find.text('Bank A'), findsNWidgets(2));
    expect(find.text('Bank B'), findsNWidgets(2));
    await tester.tap(find.text('Bank B').first);
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:nasabah-1'], bankB.id);
    expect(container.read(activeMembershipProvider).value, bankB.id);
    expect(find.byKey(AppSheetContainer.surfaceKey), findsNothing);
  });

  testWidgets('concurrent bank switch taps cannot overwrite the first choice',
      (tester) async {
    final storage = _SlowStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    await pumpPanel(
      tester,
      memberships: [
        bankA,
        bankB,
        membershipRow('membership-c', nama: 'Bank C')
      ],
      storage: storage,
    );

    await tester.tap(find.text('Bank B').first);
    await storage.writeStarted.future.timeout(const Duration(seconds: 2));
    await tester.tap(find.text('Bank C').first);
    storage.releaseWrite.complete();
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:nasabah-1'], bankB.id);
    expect(find.byKey(AppSheetContainer.surfaceKey), findsNothing);
  });

  testWidgets('failed bank selection keeps the active choice and retries',
      (tester) async {
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final container = await pumpPanel(
      tester,
      memberships: [bankA, bankB],
      storage: storage,
    );
    storage.putFailure = StateError('storage unavailable');

    await tester.tap(find.text('Bank B').first);
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
    expect(container.read(activeMembershipProvider).value, bankA.id);
    expect(find.text('Pilihan belum tersimpan. Bank aktif tidak berubah.'),
        findsOneWidget);
    expect(find.byKey(AppSheetContainer.surfaceKey), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(storage.values['active_membership_id:nasabah-1'], bankB.id);
    expect(container.read(activeMembershipProvider).value, bankB.id);
    expect(find.byKey(AppSheetContainer.surfaceKey), findsNothing);
  });

  testWidgets('unavailable approved bank is labeled and cannot be selected',
      (tester) async {
    final unavailable = membershipRow(
      'membership-offline',
      nama: 'Bank Tidak Tersedia',
      dibuka: false,
    );
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    final container = await pumpPanel(
      tester,
      memberships: [bankA, unavailable],
      storage: storage,
    );

    expect(find.text('Bank Tidak Tersedia'), findsNWidgets(2));
    expect(find.text('Tidak tersedia'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    await tester.tap(find.text('Bank Tidak Tersedia').first);
    await tester.pumpAndSettle();

    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
    expect(container.read(activeMembershipProvider).value, bankA.id);
    expect(find.byKey(AppSheetContainer.surfaceKey), findsOneWidget);
  });

  testWidgets('history includes approved rows without duplicate actions',
      (tester) async {
    final pending = membershipRow(
      'pending',
      nama: 'Bank Menunggu',
      status: MembershipStatus.pending,
      dibuka: false,
    );
    final duplicateBankA = NasabahMembershipEntity(
      id: 'membership-a-old',
      bankSampahId: bankA.bankSampahId,
      bankSampahNama: bankA.bankSampahNama,
      bankSampahKota: bankA.bankSampahKota,
      bankSampahAlamat: bankA.bankSampahAlamat,
      status: MembershipStatus.approved,
      isActive: false,
      dapatDibuka: false,
    );
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    await pumpPanel(
      tester,
      memberships: [bankA, pending, duplicateBankA],
      storage: storage,
      scrollToHistory: true,
    );

    expect(find.text('Bank diikuti'), findsOneWidget);
    expect(find.text('Bank A'), findsNWidgets(2));
    expect(find.text('Bank Menunggu'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Disetujui'), findsNWidgets(2));
    // The detail action belongs to the followed row, not the approved copy in
    // history.
    expect(find.text('Detail Bank Sampah'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('approved history rows open details without switching banks',
      (tester) async {
    final storage = MemoryAppStorage()
      ..values['active_membership_id:nasabah-1'] = bankA.id;
    await pumpPanel(
      tester,
      memberships: [
        bankA,
        membershipRow(
          'pending',
          nama: 'Bank Menunggu',
          status: MembershipStatus.pending,
          dibuka: false,
        ),
      ],
      storage: storage,
      scrollToHistory: true,
    );

    await tester.ensureVisible(find.text('Bank A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank A').last);
    await tester.pumpAndSettle();

    expect(find.text('detail Bank A'), findsOneWidget);
    expect(storage.values['active_membership_id:nasabah-1'], bankA.id);
  });

  testWidgets('application action requires an existing membership',
      (tester) async {
    await pumpPanel(
      tester,
      memberships: [],
      storage: MemoryAppStorage(),
    );

    expect(find.text('Bank diikuti'), findsNothing);
    expect(find.text('Ajukan bank baru'), findsNothing);
    expect(find.text('Riwayat pengajuan'), findsOneWidget);
    expect(find.text('Belum ada riwayat pengajuan'), findsOneWidget);
  });

  testWidgets('eligible member can apply from panel and refresh the history',
      (tester) async {
    final container = await pumpPanel(
      tester,
      memberships: [bankA],
      storage: MemoryAppStorage(),
    );
    final notifier = container.read(nasabahApprovalProvider.notifier)
        as TestNasabahApprovalNotifier;

    await tester.tap(find.text('Ajukan bank baru'));
    await tester.pumpAndSettle();
    expect(find.text('Kirim pengajuan'), findsOneWidget);
    notifier.loadCalls.clear();
    await tester.tap(find.text('Kirim pengajuan'));
    await tester.pumpAndSettle();

    expect(notifier.loadCalls, [true]);
    expect(find.byKey(AppSheetContainer.surfaceKey), findsOneWidget);
  });

  testWidgets('panel hides membership data after the owner session changes',
      (tester) async {
    final container = await pumpPanel(
      tester,
      memberships: [bankA],
      storage: MemoryAppStorage(),
    );
    final auth = container.read(authenticationProvider.notifier)
        as TestAuthenticationNotifier;

    auth.setStateForTest(Authenticated(
      authEntity: const AuthEntity(
        id: 'another-user',
        name: 'Other',
        email: 'other@example.test',
        photoUrl: '',
        token: 'token-2',
        role: 'nasabah',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sesi berubah. Tutup panel dan masuk kembali.'),
        findsOneWidget);
    expect(find.text('Bank A'), findsNothing);
    expect(find.text('Ajukan bank baru'), findsNothing);
  });
}

class _SlowStorage extends MemoryAppStorage {
  final writeStarted = Completer<void>();
  final releaseWrite = Completer<void>();

  @override
  Future<void> put(String key, dynamic value) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    await releaseWrite.future;
    await super.put(key, value);
  }
}
