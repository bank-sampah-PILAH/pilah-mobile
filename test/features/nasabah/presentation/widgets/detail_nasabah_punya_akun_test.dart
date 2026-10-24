import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/nasabah/domain/entities/nasabah_entity.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/edit_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_list_item.dart';
import '../../../../support/nasabah_support.dart';

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

/// Membuka sheet lewat `showModalBottomSheet` di dalam GoRouter, seperti pada
/// aplikasi: tombol Edit memanggil `context.pop()` untuk menutup sheet ini
/// sebelum membuka form, dan itu memerlukan router di atasnya.
Widget _hostRute(NasabahEntity nasabah, TestNasabahNotifier notifier) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DetailNasabahBottomSheet(
                  nasabah: nasabah,
                ),
              ),
              child: const Text('Buka detail'),
            ),
          ),
        ),
      ),
    ],
  );
  return withNasabahProvider(
    notifier,
    MaterialApp.router(routerConfig: router),
  );
}

void main() {
  Widget host(NasabahEntity nasabah) => withNasabahProvider(
        TestNasabahNotifier(),
        MaterialApp(
          home: Scaffold(
            body: DetailNasabahBottomSheet(nasabah: nasabah),
          ),
        ),
      );

  group('Detail nasabah menandai profil yang dikelola nasabah (PIL-206)', () {
    testWidgets('nasabah berakun menampilkan keterangan profil terkunci',
        (tester) async {
      await tester.pumpWidget(host(_nasabah(punyaAkun: true)));

      expect(find.text('Email dikelola oleh nasabah'), findsOneWidget);
      expect(
        find.text(
          'Pengurus dapat memperbaiki data lain, tetapi tidak emailnya.',
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

      expect(find.text('Email dikelola oleh nasabah'), findsNothing);
    });

    testWidgets('data tanpa penanda penautan dianggap belum tertaut',
        (tester) async {
      // Pemanggil lama belum mengirim penanda ini. Menganggapnya terkunci akan
      // membuat pengurus kehilangan kendali atas nasabah tanpa akun.
      await tester.pumpWidget(host(_nasabah()));

      expect(find.text('Email dikelola oleh nasabah'), findsNothing);
    });
  });

  testWidgets('item daftar meneruskan penanda penautan ke sheet detail',
      (tester) async {
    // Penandanya berjalan dari daftar ke item lalu ke sheet; kalau sambungan
    // itu putus, layar detail kembali tampak dapat disunting sepenuhnya.
    await tester.pumpWidget(withNasabahProvider(
      TestNasabahNotifier(),
      MaterialApp(
        home: Scaffold(
          body: NasabahListItem(nasabah: _nasabah(punyaAkun: true)),
        ),
      ),
    ));

    await tester.tap(find.byType(NasabahListItem));
    await tester.pumpAndSettle();

    expect(find.text('Email dikelola oleh nasabah'), findsOneWidget);
  });

  group('Aksi pada sheet detail membawa entity yang sama (PIL-206)', () {
    late TestNasabahNotifier notifier;

    setUp(() {
      notifier = TestNasabahNotifier()..fetchSummary = (_) async => null;
    });

    Future<void> bukaDetail(WidgetTester tester, NasabahEntity nasabah) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_hostRute(nasabah, notifier));
      await tester.tap(find.text('Buka detail'));
      await tester.pumpAndSettle();
    }

    testWidgets('Edit Data membuka form dengan nasabah yang sama',
        (tester) async {
      await bukaDetail(tester, _nasabah(punyaAkun: true));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Data'));
      await tester.pumpAndSettle();

      expect(find.byType(EditNasabahBottomSheet), findsOneWidget);
      // Form ikut mengetahui profilnya terkunci, tanpa map perantara.
      expect(find.text('Email dikelola oleh nasabah'), findsOneWidget);
    });

    testWidgets('Nonaktifkan meminta konfirmasi untuk nasabah itu',
        (tester) async {
      await bukaDetail(tester, _nasabah());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Nonaktifkan'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Budi Santoso'), findsWidgets);
    });
  });
}
