import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

import '../../../support/harga_support.dart';
import '../../../support/pump_app.dart';
import '../../../support/stub_api.dart';

HargaEntity _jenis({HargaTerjadwal? terjadwal, bool tanpaMulai = false}) =>
    HargaEntity(
      id: 'j-1',
      kodeSampah: 'PLS-001',
      name: 'Plastik PET',
      price: 3500,
      priceFormatted: 'Rp 3.500',
      category: 'plastik',
      subtitle: '',
      badgeText: 'Anorganik',
      icon: Icons.recycling,
      iconColor: Colors.green,
      isActive: true,
      berlakuMulai: tanpaMulai ? null : DateTime(2026, 10, 7, 11),
      hargaTerjadwal: terjadwal,
    );

void main() {
  late TestHargaNotifier notifier;

  setUp(() {
    notifier = TestHargaNotifier(buildHargaNotifier(StubApi()));
  });

  /// Opens the sheet on top of a home route, the way the app shows it, so
  /// `context.pop()` after saving has somewhere to go back to.
  Future<void> bukaSheet(WidgetTester tester, HargaEntity jenis) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold()),
        GoRoute(
          path: '/edit',
          builder: (_, __) => Scaffold(
            body: TambahJenisSampahBottomSheet(
              initialData: jenis,
              now: () => DateTime(2026, 10, 7, 10),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      withHargaProvider(notifier, MaterialApp.router(routerConfig: router)),
    );
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  group('edit mode', () {
    testWidgets('warns that a price change is not retroactive (BR-03)',
        (tester) async {
      await bukaSheet(tester, _jenis());

      expect(find.textContaining('tidak berlaku surut'), findsOneWidget);
    });

    testWidgets('shows the current price, since when, and a scheduled change',
        (tester) async {
      await bukaSheet(
        tester,
        _jenis(
          terjadwal: HargaTerjadwal(
            harga: 5000,
            berlakuMulai: DateTime(2026, 10, 15),
          ),
        ),
      );

      expect(find.text('Rp 3.500/kg sejak 7 Oktober 2026'), findsOneWidget);
      expect(find.text('Rp 5.000/kg mulai 15 Oktober 2026'), findsOneWidget);
    });

    testWidgets('shows only the price when its start time is unknown',
        (tester) async {
      await bukaSheet(tester, _jenis(tanpaMulai: true));

      expect(find.text('Rp 3.500/kg'), findsOneWidget);
    });
  });

  group('saving a price change', () {
    Future<void> isiHarga(WidgetTester tester, String harga) async {
      await tester.enterText(find.widgetWithText(TextFormField, '3500'), harga);
    }

    Future<void> simpan(WidgetTester tester) async {
      final tombol = find.text('Simpan Perubahan');
      await tester.ensureVisible(tombol);
      await tester.tap(tombol);
      await tester.pumpAndSettle();
    }

    testWidgets('applies the new price now by default', (tester) async {
      await bukaSheet(tester, _jenis());

      await isiHarga(tester, '4000');
      await simpan(tester);

      expect(notifier.calls, contains('update'));
      expect(notifier.changed.single, const UbahHarga(id: 'j-1', harga: 4000));
    });

    testWidgets('schedules it from local midnight of the chosen date',
        (tester) async {
      await bukaSheet(tester, _jenis());

      await isiHarga(tester, '4000');
      final tanggalLain = find.text('Tanggal lain');
      await tester.ensureVisible(tanggalLain);
      await tester.tap(tanggalLain);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await simpan(tester);

      expect(
        notifier.changed.single,
        UbahHarga(id: 'j-1', harga: 4000, berlakuMulai: DateTime(2026, 10, 8)),
      );
    });

    testWidgets(
        'says the other fields were saved when only the new price fails, '
        'and keeps the sheet open to retry', (tester) async {
      // The PUT has already stored the other fields; reporting a plain
      // failure would hide that, and a retry only needs the price again.
      notifier.priceChangeError = NetworkException(message: 'Server sibuk');
      await bukaSheet(tester, _jenis());

      await isiHarga(tester, '4000');
      final tombol = find.text('Simpan Perubahan');
      await tester.ensureVisible(tombol);
      await tester.tap(tombol);
      await pumpToast(tester);

      expect(find.text('Harga Belum Tersimpan'), findsOneWidget);
      expect(
        find.textContaining('Perubahan lain sudah tersimpan'),
        findsOneWidget,
      );
      expect(find.textContaining('Server sibuk'), findsOneWidget);
      expect(tombol, findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('does not record a version when the price is unchanged',
        (tester) async {
      await bukaSheet(tester, _jenis());

      await simpan(tester);

      expect(notifier.calls, contains('update'));
      expect(notifier.changed, isEmpty);
    });

    testWidgets('going back to Sekarang after picking a date applies it now',
        (tester) async {
      await bukaSheet(tester, _jenis());

      await isiHarga(tester, '4000');
      final tanggalLain = find.text('Tanggal lain');
      await tester.ensureVisible(tanggalLain);
      await tester.tap(tanggalLain);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sekarang'));
      await tester.pumpAndSettle();
      await simpan(tester);

      expect(notifier.changed.single, const UbahHarga(id: 'j-1', harga: 4000));
    });
  });
}
