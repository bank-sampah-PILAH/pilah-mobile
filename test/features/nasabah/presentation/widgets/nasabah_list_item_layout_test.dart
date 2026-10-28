import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';

NasabahEntity _nasabah(String name, {String customerId = 'NAS-0002'}) =>
    NasabahEntity(
      id: 'NAS-0002',
      idNasabah: customerId,
      name: name,
      phone: '+628333333332',
      balance: 'Rp 484.250',
      isActive: true,
      address: 'Jl. Melati',
      initials: 'NK',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      status: 'approved',
    );

void main() {
  testWidgets(
      'a legacy 30-character ID stays below the name without overlapping balance',
      (tester) async {
    const customerId = 'NAS-00000000000000000000000001';
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: NasabahListItem(
            nasabah: _nasabah('Siti Aminah', customerId: customerId),
          ),
        ),
      ),
    ));

    final idFinder = find.text('ID: $customerId');
    expect(idFinder, findsOneWidget);
    final idText = tester.widget<Text>(idFinder);
    expect(idText.maxLines, 1);
    expect(idText.overflow, TextOverflow.ellipsis);
    final name = tester.getRect(find.text('Siti Aminah'));
    final id = tester.getRect(idFinder);
    final phone = tester.getRect(find.text('+628333333332'));
    final balance = tester.getRect(find.text('Rp 484.250'));
    expect(id.top, greaterThanOrEqualTo(name.bottom));
    expect(phone.top, greaterThanOrEqualTo(id.bottom));
    expect(balance.left - id.right, greaterThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long name keeps a gap before the balance', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: NasabahListItem(
            nasabah: _nasabah('Nasabah Kedua PILAH E2E Sejahtera Makmur'),
          ),
        ),
      ),
    ));

    final name = tester.getRect(find.textContaining('Nasabah Kedua'));
    final balance = tester.getRect(find.text('Rp 484.250'));
    expect(balance.left - name.right, greaterThanOrEqualTo(8));
  });

  testWidgets('the card is announced as a button that reads the nasabah',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: NasabahListItem(nasabah: _nasabah('Nasabah Kedua')),
        ),
      ),
    ));

    final node = tester.getSemantics(find.byType(NasabahListItem));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    expect(node.getSemanticsData().label, contains('Nasabah Kedua'));
    expect(node.getSemanticsData().label, contains('ID: NAS-0002'));
    handle.dispose();
  });
}
