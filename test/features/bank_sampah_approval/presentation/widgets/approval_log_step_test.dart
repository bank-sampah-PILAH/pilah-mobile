import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/approval_log_step.dart';

void main() {
  test('formatApprovalLogDate includes hour, minute and second', () {
    // Constructed as local time directly (not via .toLocal() on a UTC
    // instant), so the expected string is deterministic regardless of the
    // machine's timezone.
    final local = DateTime(2026, 9, 27, 9, 5, 3);

    expect(formatApprovalLogDate(local), '27 Sep 2026 · 09:05:03');
  });

  testWidgets('renders an appealed entry with its message', (tester) async {
    final entry = ApprovalLogEntity(
      status: ApprovalLogStatus.appealed,
      catatan: 'Dokumen sudah saya lengkapi',
      createdAt: DateTime.utc(2026, 9, 27, 10),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ApprovalLogStep(entry: entry, isLast: true),
      ),
    ));

    expect(find.text('Diajukan Banding'), findsOneWidget);
    expect(find.text('Dokumen sudah saya lengkapi'), findsOneWidget);
  });
}
