import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/approval_log_step.dart';

void main() {
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
