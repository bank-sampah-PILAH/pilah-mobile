import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/active_membership_scope.dart';

import '../../../../support/active_membership_support.dart';
import '../../../../support/auth_support.dart';
import '../../../../support/nasabah_approval_support.dart';

void main() {
  late TestAuthenticationNotifier auth;

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
  });

  /// Pumps a scope whose builder records every bank it is handed, so a test
  /// reads the sequence of banks the screens inside would have asked for.
  Future<(List<String?>, List<ActiveMembership>)> pumpScope(
    WidgetTester tester, {
    String? membershipId,
    MemoryAppStorage? storage,
    List<NasabahMembershipEntity>? memberships,
  }) async {
    final seen = <String?>[];
    final handles = <ActiveMembership>[];
    await tester.pumpWidget(withAuthenticationProvider(
      auth,
      MaterialApp(
        home: Scaffold(
          body: ActiveMembershipScope(
            membershipId: membershipId,
            builder: (context, membership) {
              seen.add(membership.id);
              handles.add(membership);
              return Text('bank ${membership.id}');
            },
          ),
        ),
      ),
      overrides: [
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
    return (seen, handles);
  }

  testWidgets('builds with the bank the nasabah last chose', (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-a');

    final (seen, _) = await pumpScope(
      tester,
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );

    // Resolved before the first build, so a screen inside never fetches the
    // wrong bank first and the right one after.
    expect(seen, ['membership-a']);
  });

  testWidgets('a named bank wins over the saved one while the screen is open',
      (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-a');

    final (seen, _) = await pumpScope(
      tester,
      membershipId: 'membership-b',
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );

    expect(seen, ['membership-b']);
  });

  testWidgets('without storage there is no bank to resolve', (tester) async {
    final (seen, _) = await pumpScope(tester);

    // Null is not an error: the screen asks the API without a membership and
    // shows whatever it answers, which is how the picker still appears.
    expect(seen, [null]);
  });

  testWidgets('a bank that cannot be read resolves to none', (tester) async {
    final storage = _UnreadableStorage();

    final (seen, _) = await pumpScope(
      tester,
      storage: storage,
      memberships: [membershipRow('membership-a')],
    );

    expect(seen, [null]);
  });

  testWidgets('follows a switch made elsewhere', (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-a');

    final (seen, _) = await pumpScope(
      tester,
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );
    expect(seen, ['membership-a']);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ActiveMembershipScope)),
    );
    await container
        .read(activeMembershipProvider.notifier)
        .select('membership-b');
    await tester.pumpAndSettle();

    expect(seen, ['membership-a', 'membership-b']);
  });

  testWidgets('a pick is remembered as the active bank', (tester) async {
    final storage = MemoryAppStorage();

    final (seen, handles) = await pumpScope(
      tester,
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );

    await handles.last.select('membership-b');
    await tester.pumpAndSettle();

    expect(seen.last, 'membership-b');
    expect(storage.values['active_membership_id:nasabah-1'], 'membership-b');
  });

  testWidgets('asking for the chooser back remembers nothing', (tester) async {
    final storage = MemoryAppStorage();
    await ActiveMembershipSelection(storage)
        .select('nasabah-1', 'membership-a');

    final (seen, handles) = await pumpScope(
      tester,
      storage: storage,
      memberships: [
        membershipRow('membership-a'),
        membershipRow('membership-b'),
      ],
    );

    await handles.last.select(null);
    await tester.pumpAndSettle();

    // The screen asks without a membership, which is what makes the backend
    // offer the banks to pick from, and the saved bank is left alone.
    expect(seen, ['membership-a', null]);
    expect(storage.values['active_membership_id:nasabah-1'], 'membership-a');
  });
}

/// Storage whose reads throw, standing in for a platform channel that fails
/// after a choice was saved.
class _UnreadableStorage extends MemoryAppStorage {
  @override
  Future<T?> get<T>(String key) async =>
      throw StateError('storage unavailable');
}
