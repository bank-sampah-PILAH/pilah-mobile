import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_entity.dart';
import 'package:pilah_mobile/features/harga/domain/entities/harga_terjadwal.dart';
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

  setUp(() {
    cubit = _MockHargaCubit();
    when(() => cubit.state).thenReturn(HargaInitial());
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
}
