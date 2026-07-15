import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/superadmin/domain/entities/bank_sampah_entity.dart';
import 'package:pilah_mobile/features/superadmin/presentation/pages/superadmin_dashboard_screen.dart';

BankSampahEntity _bank({String kota = '', String alamat = ''}) => BankSampahEntity(
      id: 'b1',
      nama: 'Bank Sampah BTH',
      alamat: alamat,
      kota: kota,
      noHpPic: '+628123456789',
      fotoKegiatan: null,
      status: 'active',
      createdAt: DateTime(2026, 7, 1),
      pengelolaNama: 'Ibu Sari',
      pengelolaEmail: 'sari@example.com',
      pengelolaNoHp: '+628123456789',
    );

Future<void> _pumpCard(WidgetTester tester, BankSampahEntity bank) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: ApprovedBankCard(bank: bank)),
    ),
  ));
}

void main() {
  group('bank card location line', () {
    testWidgets('shows the city when one is on record', (tester) async {
      await _pumpCard(tester, _bank(kota: 'Depok', alamat: 'Jl. Melati 3, Depok'));

      expect(find.text('Depok'), findsOneWidget);
    });

    testWidgets('falls back to the address when no city is set', (tester) async {
      // The registration form has no city input — it asks for the city inside
      // the address — so this is what every app-registered bank looks like.
      await _pumpCard(
        tester,
        _bank(alamat: 'Jl. Melati 3, RT 04/RW 02, Kukusan, Beji, Depok'),
      );

      expect(
        find.text('Jl. Melati 3, RT 04/RW 02, Kukusan, Beji, Depok'),
        findsOneWidget,
      );
      expect(
        find.text('Kota tidak dicantumkan'),
        findsNothing,
        reason: 'the city is in the address — nothing is actually missing',
      );
    });

    testWidgets('shows no placeholder when there is genuinely no location',
        (tester) async {
      await _pumpCard(tester, _bank());

      expect(find.text('Kota tidak dicantumkan'), findsNothing);
      expect(find.text('Bank Sampah BTH'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long address stays on one line and does not overflow',
        (tester) async {
      await _pumpCard(
        tester,
        _bank(
          alamat: 'Jl. Raya Margonda No. 525 Blok A2 Lantai 3, RT 004 / RW 011, '
              'Kelurahan Kemiri Muka, Kecamatan Beji, Kota Depok, Jawa Barat 16423',
        ),
      );

      // pumpWidget surfaces a RenderFlex overflow as an exception.
      expect(tester.takeException(), isNull);
    });
  });
}
