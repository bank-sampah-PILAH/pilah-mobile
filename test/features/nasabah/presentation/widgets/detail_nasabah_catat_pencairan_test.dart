import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_cubit.dart';
import 'package:pilah_mobile/features/nasabah/presentation/cubit/nasabah_state.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/detail_nasabah_bottom_sheet.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/catat_pencairan_page.dart';

class _MockNasabahCubit extends MockCubit<NasabahState>
    implements NasabahCubit {}

Map<String, dynamic> _customer({required bool isActive}) => {
      'id': 'n-1',
      'isActive': isActive,
      'initials': 'AR',
      'name': 'Ahmad Ridwan',
      'phone': '081234567890',
      'balance': 'Rp 465.600',
      'idNasabah': 'NAS-0001',
    };

void main() {
  late _MockNasabahCubit nasabahCubit;
  CatatPencairanArgs? openedWith;

  setUp(() {
    openedWith = null;
    nasabahCubit = _MockNasabahCubit();
    when(() => nasabahCubit.fetchRingkasan(any()))
        .thenAnswer((_) async => null);
    when(() => nasabahCubit.loadNasabah(silent: any(named: 'silent')))
        .thenAnswer((_) async {});
  });

  /// Opens the sheet the way the nasabah list does, as a modal bottom sheet.
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
                  customerData: _customer(isActive: isActive),
                  nasabahCubit: nasabahCubit,
                ),
              ),
              child: const Text('buka'),
            ),
          ),
        ),
        GoRoute(
          path: CatatPencairanPage.route,
          builder: (context, state) {
            openedWith = state.extra as CatatPencairanArgs?;
            return Scaffold(
              body: TextButton(
                onPressed: () => context.pop(true),
                child: const Text('pencairan tercatat'),
              ),
            );
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers Catat Pencairan for an active nasabah', (tester) async {
    await openSheet(tester, isActive: true);

    expect(find.text('Catat Pencairan'), findsOneWidget);
  });

  testWidgets('hides Catat Pencairan for an inactive nasabah', (tester) async {
    await openSheet(tester, isActive: false);

    expect(find.text('Catat Pencairan'), findsNothing);
  });

  testWidgets('opens the form for this nasabah and refreshes after recording',
      (tester) async {
    await openSheet(tester, isActive: true);

    final button = find.text('Catat Pencairan');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(openedWith?.nasabahId, 'n-1');
    expect(openedWith?.nasabahNama, 'Ahmad Ridwan');

    await tester.tap(find.text('pencairan tercatat'));
    await tester.pumpAndSettle();

    verify(() => nasabahCubit.loadNasabah(silent: true)).called(1);
  });
}
