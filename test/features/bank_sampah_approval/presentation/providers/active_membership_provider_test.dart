import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/nasabah_approval_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/states/nasabah_approval_state.dart';

import '../../../../support/active_membership_support.dart';
import '../../../../support/nasabah_approval_support.dart';

ProviderContainer _container(
  MemoryAppStorage storage,
  List<NasabahMembershipEntity> memberships, {
  String userId = 'user-1',
}) {
  final container = ProviderContainer(
    overrides: [
      activeMembershipSelectionProvider
          .overrideWithValue(ActiveMembershipSelection(storage)),
      activeMembershipUserIdProvider.overrideWithValue(userId),
      nasabahApprovalProvider.overrideWith(
        () => TestNasabahApprovalNotifier(
          initialState: NasabahApprovalLoaded(memberships),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('settles on the first openable bank when nothing was chosen yet',
      () async {
    final storage = MemoryAppStorage();
    final container = _container(storage, [
      membershipRow('closed', dibuka: false),
      membershipRow('first-open'),
      membershipRow('second-open'),
    ]);

    expect(await container.read(activeMembershipProvider.future), 'first-open');
  });

  test('choosing another openable bank remembers it', () async {
    final storage = MemoryAppStorage();
    final container = _container(storage, [
      membershipRow('first-open'),
      membershipRow('second-open'),
    ]);
    expect(await container.read(activeMembershipProvider.future), 'first-open');

    await container
        .read(activeMembershipProvider.notifier)
        .select('second-open');

    expect(container.read(activeMembershipProvider).value, 'second-open');
    expect(
      await ActiveMembershipSelection(storage).read('user-1'),
      'second-open',
    );
  });

  test('a save that fails keeps the previous bank and reports the error',
      () async {
    final storage = MemoryAppStorage();
    final container = _container(storage, [
      membershipRow('first-open'),
      membershipRow('second-open'),
    ]);
    expect(await container.read(activeMembershipProvider.future), 'first-open');

    storage.putFailure = Exception('penyimpanan penuh');
    // Choosing must not throw at the caller: it answers false instead, so a
    // rejected write cannot escape as an unhandled async error.
    final saved = await container
        .read(activeMembershipProvider.notifier)
        .select('second-open');

    expect(saved, isFalse);
    expect(container.read(activeMembershipProvider).value, 'first-open');
    expect(
      await ActiveMembershipSelection(storage).read('user-1'),
      'first-open',
    );
  });
}
