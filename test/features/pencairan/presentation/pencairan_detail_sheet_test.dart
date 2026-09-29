import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_detail_sheet.dart';

Pencairan _pencairan({bool diperbarui = false}) => Pencairan(
      id: 'p-9',
      nasabahId: 'n-1',
      nasabahNama: 'Budi Santoso',
      nominal: 150000,
      metode: MetodePencairan.transfer,
      tanggal: DateTime(2026, 9, 22, 11),
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 465600,
      saldoSesudah: 315600,
      dicatatOlehNama: 'Ibu Sari',
      diperbarui: diperbarui,
    );

void main() {
  late int changes;

  setUp(() => changes = 0);

  /// Opens the pengurus sheet from a real GoRouter, with stub edit and history
  /// routes that report what they were opened with. The edit stub pops
  /// [editResult], like the real form after saving (true) or leaving (null).
  Future<void> openSheet(
    WidgetTester tester,
    Pencairan item, {
    bool? editResult,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPencairanDetailSheet(
                  context,
                  item,
                  onChanged: () => changes++,
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: EditPencairanPage.route,
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(editResult),
              child: Text('edit ${(state.extra! as Pencairan).id}'),
            ),
          ),
        ),
        GoRoute(
          path: RevisiPencairanPage.route,
          builder: (_, state) =>
              Scaffold(body: Text('revisi ${state.extra! as String}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('a saved edit closes the sheet and refreshes the caller',
      (tester) async {
    await openSheet(tester, _pencairan(), editResult: true);

    await tapKey(tester, 'edit-pencairan');
    expect(find.text('Detail Pencairan'), findsNothing);
    expect(find.text('edit p-9'), findsOneWidget);

    await tester.tap(find.text('edit p-9'));
    await tester.pumpAndSettle();

    expect(changes, 1);
    expect(find.text('buka'), findsOneWidget);
  });

  testWidgets('leaving the edit form without saving refreshes nothing',
      (tester) async {
    await openSheet(tester, _pencairan());

    await tapKey(tester, 'edit-pencairan');
    await tester.tap(find.text('edit p-9'));
    await tester.pumpAndSettle();

    expect(changes, 0);
  });

  testWidgets('an edited pencairan links to its change history',
      (tester) async {
    await openSheet(tester, _pencairan(diperbarui: true));

    expect(find.text('Diperbarui'), findsOneWidget);
    await tapKey(tester, 'riwayat-perubahan-pencairan');

    expect(find.text('Detail Pencairan'), findsNothing);
    expect(find.text('revisi p-9'), findsOneWidget);
    expect(changes, 0);
  });

  testWidgets('a pencairan never edited has no change-history link',
      (tester) async {
    await openSheet(tester, _pencairan());

    expect(find.byKey(const Key('edit-pencairan')), findsOneWidget);
    expect(find.byKey(const Key('riwayat-perubahan-pencairan')), findsNothing);
    expect(find.text('Diperbarui'), findsNothing);
  });
}
