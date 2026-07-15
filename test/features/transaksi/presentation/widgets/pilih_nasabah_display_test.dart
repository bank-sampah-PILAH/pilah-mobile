import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/pilih_nasabah_section.dart';

const _uuid = '2bb26f62-9f4e-4b1a-8c3d-7e5a1f0c9d84';

NasabahEntity _nasabah({String kode = 'BEAST-381231'}) => NasabahEntity(
      id: _uuid,
      idNasabah: kode,
      name: 'Budi Santoso',
      phone: '0812-3456-7890',
      balance: 'Rp 50.000',
      isActive: true,
      address: 'Jl. Melati 3',
      initials: 'BS',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
    );

Widget _host(NasabahEntity? selected) => MaterialApp(
      home: Scaffold(
        body: PilihNasabahSection(
          selectedCustomer: selected,
          onCustomerSelected: (_) {},
        ),
      ),
    );

void main() {
  group('PilihNasabahSection', () {
    testWidgets('shows the human-readable kode, never the backend UUID',
        (tester) async {
      await tester.pumpWidget(_host(_nasabah()));

      expect(find.text('BEAST-381231'), findsOneWidget);
      expect(
        find.text(_uuid),
        findsNothing,
        reason: 'a UUID is meaningless to the user picking a nasabah',
      );
    });

    testWidgets('falls back to no identifier rather than the UUID when the '
        'kode is missing', (tester) async {
      await tester.pumpWidget(_host(_nasabah(kode: '')));

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(
        find.text(_uuid),
        findsNothing,
        reason: 'an absent kode must not reintroduce the UUID',
      );
    });
  });
}
