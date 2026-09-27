import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';

void main() {
  Map<String, dynamic> customerData({bool? punyaAkun}) => {
        'id': 'nasabah-1',
        'isActive': true,
        'initials': 'BS',
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'phone': '+628111111111',
        'balance': 'Rp 450.000',
        'idNasabah': 'NAS-0001',
        'jenisKelamin': 'Laki-laki',
        'tanggalLahir': '01/01/1990',
        'tanggalDaftar': '12/05/2026',
        'address': 'Jl. Mawar No. 12',
        if (punyaAkun != null) 'punyaAkun': punyaAkun,
      };

  Widget host(Map<String, dynamic> data) => MaterialApp(
        home: Scaffold(
          body: DetailNasabahBottomSheet(customerData: data),
        ),
      );

  group('Detail nasabah menandai profil yang dikelola nasabah (PIL-206)', () {
    testWidgets('nasabah berakun menampilkan keterangan profil terkunci',
        (tester) async {
      await tester.pumpWidget(host(customerData(punyaAkun: true)));

      expect(find.text('Profil dikelola oleh nasabah'), findsOneWidget);
      expect(
        find.text(
          'Pengurus hanya dapat mengubah nomor anggota dan status keanggotaan.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('nasabah berakun tetap menampilkan nilai profilnya',
        (tester) async {
      // Keterangan terkunci tidak boleh menyembunyikan datanya; pengurus masih
      // perlu membacanya untuk mencocokkan nasabah saat penimbangan.
      await tester.pumpWidget(host(customerData(punyaAkun: true)));

      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('+628111111111'), findsOneWidget);
      expect(find.text('Jl. Mawar No. 12'), findsOneWidget);
    });

    testWidgets('nasabah tanpa akun tidak menampilkan keterangan itu',
        (tester) async {
      await tester.pumpWidget(host(customerData(punyaAkun: false)));

      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });

    testWidgets('data tanpa penanda penautan dianggap belum tertaut',
        (tester) async {
      // Pemanggil lama belum mengirim penanda ini. Menganggapnya terkunci akan
      // membuat pengurus kehilangan kendali atas nasabah tanpa akun.
      await tester.pumpWidget(host(customerData()));

      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });
  });
}
