import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';

NasabahEntity _nasabah({bool punyaAkun = false, String status = 'approved'}) =>
    NasabahEntity(
      id: 'nasabah-1',
      idNasabah: 'NAS-0001',
      name: 'Budi Santoso',
      email: 'budi@example.com',
      phone: '+628111111111',
      balance: 'Rp 450.000',
      isActive: true,
      address: 'Jl. Mawar No. 12',
      initials: 'BS',
      avatarColor: const Color(0xFFEAF5EC),
      textColor: const Color(0xFF2F6B45),
      jenisKelamin: 'Laki-laki',
      tanggalLahir: '01/01/1990',
      tanggalDaftar: '12/05/2026',
      status: status,
      punyaAkun: punyaAkun,
    );

void main() {
  Widget host(NasabahEntity nasabah) => MaterialApp(
        home: Scaffold(
          body: DetailNasabahBottomSheet(nasabah: nasabah),
        ),
      );

  group('Detail nasabah menandai profil yang dikelola nasabah (PIL-206)', () {
    testWidgets('nasabah berakun menampilkan keterangan profil terkunci',
        (tester) async {
      await tester.pumpWidget(host(_nasabah(punyaAkun: true)));

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
      await tester.pumpWidget(host(_nasabah(punyaAkun: true)));

      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('+628111111111'), findsOneWidget);
      expect(find.text('Jl. Mawar No. 12'), findsOneWidget);
    });

    testWidgets('nasabah tanpa akun tidak menampilkan keterangan itu',
        (tester) async {
      await tester.pumpWidget(host(_nasabah(punyaAkun: false)));

      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });

    testWidgets('data tanpa penanda penautan dianggap belum tertaut',
        (tester) async {
      // Pemanggil lama belum mengirim penanda ini. Menganggapnya terkunci akan
      // membuat pengurus kehilangan kendali atas nasabah tanpa akun.
      await tester.pumpWidget(host(_nasabah()));

      expect(find.text('Profil dikelola oleh nasabah'), findsNothing);
    });
  });

  testWidgets('item daftar meneruskan penanda penautan ke sheet detail',
      (tester) async {
    // Penandanya berjalan dari daftar ke item lalu ke sheet; kalau sambungan
    // itu putus, layar detail kembali tampak dapat disunting sepenuhnya.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NasabahListItem(nasabah: _nasabah(punyaAkun: true)),
      ),
    ));

    await tester.tap(find.byType(NasabahListItem));
    await tester.pumpAndSettle();

    expect(find.text('Profil dikelola oleh nasabah'), findsOneWidget);
  });
}
