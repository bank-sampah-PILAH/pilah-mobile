import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/pages/harga_page.dart';

import '../../../support/harga_support.dart';
import '../../../support/stub_api.dart';

HargaEntity _jenis(String id, {HargaTerjadwal? terjadwal}) => HargaEntity(
      id: id,
      kodeSampah: id,
      name: 'Jenis $id',
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'plastik',
      subtitle: '',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: true,
      hargaTerjadwal: terjadwal,
    );

void main() {
  testWidgets('the price list shows an upcoming price change', (tester) async {
    // A common phone width, so the extra line must fit without overflowing.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final notifier = TestHargaNotifier(
      buildHargaNotifier(StubApi()),
      initialState: HargaLoaded(jenisSampahList: [
        _jenis(
          'PLS-001',
          terjadwal: HargaTerjadwal(
            harga: 5000,
            berlakuMulai: DateTime(2026, 10, 15),
          ),
        ),
        _jenis('KRT-001'),
      ]),
    );

    await tester.pumpWidget(
      withHargaProvider(notifier, const MaterialApp(home: HargaPage())),
    );

    expect(find.text('Rp 5.000 mulai 15 Oktober 2026'), findsOneWidget);
    expect(find.textContaining('mulai'), findsOneWidget);
  });
}
