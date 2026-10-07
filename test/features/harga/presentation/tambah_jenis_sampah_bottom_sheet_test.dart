import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
import 'package:pilah_mobile/features/harga/domain/entities/ubah_harga.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_cubit.dart';
import 'package:pilah_mobile/features/harga/presentation/cubit/harga_state.dart';
import 'package:pilah_mobile/features/harga/presentation/widgets/tambah_jenis_sampah_bottom_sheet.dart';

class _MockHargaCubit extends MockCubit<HargaState> implements HargaCubit {}

HargaEntity _jenis({HargaTerjadwal? terjadwal}) => HargaEntity(
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
      berlakuMulai: DateTime(2026, 10, 7, 11),
      hargaTerjadwal: terjadwal,
    );

void main() {
  late _MockHargaCubit cubit;

  setUpAll(() {
    registerFallbackValue(_jenis());
    registerFallbackValue(const UbahHarga(id: '', harga: 0));
  });

  setUp(() {
    cubit = _MockHargaCubit();
    when(() => cubit.state).thenReturn(HargaInitial());
    when(() => cubit.updateHarga(any())).thenAnswer((_) async => null);
    when(() => cubit.ubahHarga(any())).thenAnswer((_) async => null);
  });

  tearDown(() => cubit.close());

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
              hargaCubit: cubit,
              now: () => DateTime(2026, 10, 7, 10),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
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

      verify(() => cubit.updateHarga(any())).called(1);
      verify(
        () => cubit.ubahHarga(const UbahHarga(id: 'j-1', harga: 4000)),
      ).called(1);
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

      verify(
        () => cubit.ubahHarga(
          UbahHarga(
              id: 'j-1', harga: 4000, berlakuMulai: DateTime(2026, 10, 8)),
        ),
      ).called(1);
    });

    testWidgets('does not record a version when the price is unchanged',
        (tester) async {
      await bukaSheet(tester, _jenis());

      await simpan(tester);

      verify(() => cubit.updateHarga(any())).called(1);
      verifyNever(() => cubit.ubahHarga(any()));
    });
  });
}
