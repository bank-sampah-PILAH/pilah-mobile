import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_detail_page.dart';

Widget _wrap(NasabahMembershipEntity membership) => MaterialApp(
      home: ApprovalBankSampahDetailPage(membership: membership),
    );

void main() {
  testWidgets('shows current status and the rejection reason when rejected',
      (tester) async {
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      status: MembershipStatus.rejected,
      isActive: false,
      alasanPenolakan: 'Dokumen tidak lengkap',
    );

    await tester.pumpWidget(_wrap(membership));

    expect(find.text('Bank Sampah Sejahtera'), findsOneWidget);
    expect(find.text('Ditolak'), findsWidgets);
    expect(find.text('Dokumen tidak lengkap'), findsOneWidget);
  });

  testWidgets('renders riwayat entries in the order the backend sent them',
      (tester) async {
    final membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      status: MembershipStatus.approved,
      isActive: true,
      // Newest-first, exactly as the backend sends riwayat_persetujuan: the
      // most recent decision (25 Sep, approved) comes before the older one
      // (20 Sep, rejected). A test fixture in chronological order wouldn't
      // catch an accidental re-sort into oldest-first.
      riwayat: [
        ApprovalLogEntity(
          status: ApprovalLogStatus.approved,
          catatan: 'Data lengkap',
          createdAt: DateTime(2026, 9, 25, 8),
        ),
        ApprovalLogEntity(
          status: ApprovalLogStatus.rejected,
          catatan: 'Dokumen tidak lengkap',
          createdAt: DateTime(2026, 9, 20, 10),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(membership));

    expect(find.text('Data lengkap'), findsOneWidget);
    expect(find.text('Dokumen tidak lengkap'), findsOneWidget);
    final newestDy = tester.getTopLeft(find.text('Data lengkap')).dy;
    final oldestDy = tester.getTopLeft(find.text('Dokumen tidak lengkap')).dy;
    expect(newestDy, lessThan(oldestDy));
  });

  testWidgets('renders a waiting message with no timeline for an empty riwayat',
      (tester) async {
    const membership = NasabahMembershipEntity(
      id: 'membership-1',
      bankSampahId: 'bank-1',
      bankSampahNama: 'Bank Sampah Sejahtera',
      bankSampahKota: 'Bandung',
      status: MembershipStatus.pending,
      isActive: true,
    );

    await tester.pumpWidget(_wrap(membership));

    expect(find.text('Menunggu keputusan pengurus'), findsOneWidget);
  });
}
