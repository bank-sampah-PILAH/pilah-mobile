import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/active_membership_selection.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

class _MemoryStorage implements AppStorage {
  final values = <String, Object>{};

  @override
  Future<void> init() async {}
  @override
  Future<void> put(String key, dynamic value) async => values[key] = value;
  @override
  Future<T?> get<T>(String key) async => values[key] as T?;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> clear() async => values.clear();
  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

class _DelayedMemoryStorage extends _MemoryStorage {
  final writeStarted = Completer<void>();
  final releaseFirstWrite = Completer<void>();
  var writes = 0;

  @override
  Future<void> put(String key, dynamic value) async {
    writes++;
    if (writes == 1) {
      writeStarted.complete();
      await releaseFirstWrite.future;
    }
    await super.put(key, value);
  }
}

NasabahMembershipEntity _membership(
  String id, {
  MembershipStatus status = MembershipStatus.approved,
  bool active = true,
  bool? dibuka,
}) =>
    NasabahMembershipEntity(
      id: id,
      bankSampahId: 'bank-$id',
      bankSampahNama: 'Bank $id',
      bankSampahKota: '',
      bankSampahAlamat: '',
      status: status,
      isActive: active,
      dapatDibuka: dibuka ?? (status == MembershipStatus.approved && active),
    );

void main() {
  test('a membership whose bank is closed is not selectable', () {
    final membership = _membership('one', dibuka: false);

    expect(membership.status, MembershipStatus.approved);
    expect(membership.isActive, isTrue);
    expect(isSelectableMembership(membership), isFalse);
  });
  test('selection persists and is isolated by user while allowing switches',
      () async {
    final storage = _MemoryStorage();
    final selection = ActiveMembershipSelection(storage);

    await selection.select('user-1', 'membership-a');
    await selection.select('user-1', 'membership-b');

    expect(await selection.read('user-1'), 'membership-b');
    expect(await selection.read('user-2'), isNull);
  });

  test('serializes overlapping resolutions so the newest state wins', () async {
    final storage = _DelayedMemoryStorage();
    final selection = ActiveMembershipSelection(storage);
    final otherSelection = ActiveMembershipSelection(storage);
    final stale = selection.resolve('user-1', [_membership('old')]);
    await storage.writeStarted.future;
    final latest = otherSelection.resolve('user-1', [_membership('new')]);
    await Future<void>.delayed(Duration.zero);
    final writesBeforeRelease = storage.writes;
    storage.releaseFirstWrite.complete();

    expect(await stale, 'old');
    expect(await latest, 'new');
    expect(writesBeforeRelease, 1);
    expect(await otherSelection.read('user-1'), 'new');
  });

  test(
      'resolve replaces a no-longer-eligible choice and clears when none remain',
      () async {
    final storage = _MemoryStorage();
    final selection = ActiveMembershipSelection(storage);
    await selection.select('user-1', 'old');

    final replacement = await selection.resolve('user-1', [
      _membership('old', status: MembershipStatus.pending),
      _membership('new'),
    ]);

    expect(replacement, 'new');
    expect(await selection.read('user-1'), 'new');
    expect(
      await selection.resolve('user-1', [
        _membership('new', active: false),
      ]),
      isNull,
    );
    expect(await selection.read('user-1'), isNull);
  });
}
