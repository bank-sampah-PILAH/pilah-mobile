import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

void main() {
  test('ApprovalLogEntity.fromJson parses an appealed entry', () {
    final entry = ApprovalLogEntity.fromJson({
      'status': 'appealed',
      'catatan': 'Dokumen sudah saya lengkapi',
      'created_at': '2026-09-27T10:00:00Z',
    });

    expect(entry.status, ApprovalLogStatus.appealed);
    expect(entry.catatan, 'Dokumen sudah saya lengkapi');
  });

  test('reads dapat_dibuka from the row', () {
    final membership = NasabahMembershipEntity.fromJson({
      'id': 'm1',
      'status': 'approved',
      'is_active': true,
      'dapat_dibuka': true,
      'bank_sampah': {'id': 'b1', 'nama': 'Bank Sampah Melati'},
    });

    expect(membership.dapatDibuka, isTrue);
  });

  test('treats a row without dapat_dibuka as not openable', () {
    final membership = NasabahMembershipEntity.fromJson({
      'id': 'm1',
      'status': 'approved',
      'is_active': true,
      'bank_sampah': {'id': 'b1', 'nama': 'Bank Sampah Melati'},
    });

    expect(membership.dapatDibuka, isFalse);
  });
}
