import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';

NasabahEntity _nasabah(String name) => NasabahEntity(
      id: 'NAS-0002',
      idNasabah: 'NAS-0002',
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
}
