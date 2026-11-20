import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/membership_list_item.dart';

void main() {
  const membership = NasabahMembershipEntity(
    id: 'm1',
    bankSampahId: 'b1',
    bankSampahNama: 'Bank Sampah Melati',
    bankSampahKota: 'Depok',
    bankSampahAlamat: 'Jl. Melati 1',
    status: MembershipStatus.pending,
    isActive: false,
  );

  Widget host(VoidCallback onTap, {bool isActive = false}) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: MembershipListItem(
              membership: membership,
              onTap: onTap,
              isActive: isActive,
            ),
          ),
        ),
      );

  testWidgets('the card is a button that reads the bank sampah',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(() {}));

    final node = tester.getSemantics(find.byType(MembershipListItem));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    expect(node.getSemanticsData().label, contains('Bank Sampah Melati'));
    handle.dispose();
  });

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(() => taps++));

    await tester.tap(find.text('Bank Sampah Melati'));

    expect(taps, 1);
  });

  testWidgets('marks only the bank that is active', (tester) async {
    await tester.pumpWidget(host(() {}));
    expect(find.text('Aktif'), findsNothing);

    await tester.pumpWidget(host(() {}, isActive: true));
    expect(find.text('Aktif'), findsOneWidget);
  });
}
