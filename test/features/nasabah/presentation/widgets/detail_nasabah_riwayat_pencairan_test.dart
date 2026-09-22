import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_page.dart';

class _MockNasabahCubit extends MockCubit<NasabahState>
    implements NasabahCubit {}

void main() {
  late _MockNasabahCubit nasabahCubit;
  RiwayatPencairanArgs? openedWith;
  var opened = false;

  setUp(() {
    openedWith = null;
    opened = false;
    nasabahCubit = _MockNasabahCubit();
    when(() => nasabahCubit.fetchRingkasan(any()))
        .thenAnswer((_) async => null);
  });

  Future<void> openSheet(WidgetTester tester, {required bool isActive}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DetailNasabahBottomSheet(
                  customerData: {
                    'id': 'n-1',
                    'isActive': isActive,
                    'name': 'Ahmad Ridwan',
                    'balance': 'Rp 465.600',
                  },
                  nasabahCubit: nasabahCubit,
                ),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
        GoRoute(
          path: RiwayatPencairanPage.route,
          builder: (context, state) {
            opened = true;
            openedWith = state.extra as RiwayatPencairanArgs?;
            return const Scaffold(body: Text('riwayat'));
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  for (final isActive in [true, false]) {
    testWidgets(
        'opens the riwayat of this nasabah '
        '(${isActive ? 'active' : 'inactive'})', (tester) async {
      await openSheet(tester, isActive: isActive);

      final button = find.text('Riwayat Pencairan');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(opened, isTrue);
      expect(openedWith?.nasabahId, 'n-1');
      expect(openedWith?.nasabahNama, 'Ahmad Ridwan');
    });
  }
}
