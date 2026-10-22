import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/revisi_pencairan_cubit.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/edit_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/revisi_pencairan_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/widgets/pencairan_detail_sheet.dart';

Pencairan _pencairan({bool diperbarui = false, int potongan = 0}) => Pencairan(
      id: 'p-9',
      nasabahId: 'n-1',
      nasabahNama: 'Budi Santoso',
      nominal: 150000,
      potongan: potongan,
      metode: MetodePencairan.transfer,
      tanggal: DateTime(2026, 9, 22, 11),
      keterangan: '',
      status: 'tercatat',
      saldoSebelum: 465600,
      saldoSesudah: 315600,
      dicatatOlehNama: 'Ibu Sari',
      diperbarui: diperbarui,
    );

class _MockUseCases extends Mock implements PencairanUseCases {}

void main() {
  setUpAll(() {
    registerFallbackValue(EditPencairanRequest(
      id: '',
      nominal: 0,
      metode: MetodePencairan.tunai,
      tanggal: DateTime(2026),
      keterangan: '',
      alasan: '',
    ));
  });

  late int changes;

  setUp(() => changes = 0);

  /// Opens the pengurus sheet from a real GoRouter, with stub edit and history
  /// routes that report what they were opened with. The edit stub pops
  /// [editResult], like the real form after saving (true) or leaving (null).
  Future<void> openSheet(
    WidgetTester tester,
    Pencairan item, {
    bool? editResult,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
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

  testWidgets('a pencairan with a potongan shows what was paid out',
      (tester) async {
    await openSheet(tester, _pencairan(potongan: 10000));

    expect(find.text('Potongan'), findsOneWidget);
    expect(find.text('Rp 10.000'), findsOneWidget);
    expect(find.text('Dibayar'), findsOneWidget);
    expect(find.text('Rp 140.000'), findsOneWidget);
  });

  testWidgets('the nominal is red and the saldo moves from before to after',
      (tester) async {
    await openSheet(tester, _pencairan());

    expect(tester.widget<Text>(find.text('Rp 150.000').first).style!.color,
        AppColors.danger);
    expect(find.text('Rp 465.600'), findsOneWidget);
    expect(find.text('Rp 315.600'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text('Tercatat'), findsOneWidget);
  });

  testWidgets('a wide window opens the detail as a dialog', (tester) async {
    await openSheet(tester, _pencairan(), size: const Size(1200, 900));

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('on a wide window edit opens as a dialog, not a page',
      (tester) async {
    final useCases = _MockUseCases();
    di.registerFactory<PencairanUseCases>(() => useCases);
    addTearDown(() => di.unregister<PencairanUseCases>());
    await openSheet(tester, _pencairan(),
        editResult: true, size: const Size(1200, 900));

    await tapKey(tester, 'edit-pencairan');

    expect(find.text('edit p-9'), findsNothing, reason: 'not the route');
    expect(find.byType(Dialog), findsOneWidget, reason: 'the same dialog');
    expect(find.text('Edit Pencairan'), findsOneWidget);
    expect(find.byKey(const Key('nominal-field')), findsOneWidget);
    expect(find.byKey(const Key('submit-edit-pencairan')), findsOneWidget);

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pencairan'), findsOneWidget);
    expect(find.byKey(const Key('nominal-field')), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('on a wide window the history opens as a dialog', (tester) async {
    final useCases = _MockUseCases();
    when(() => useCases.getRevisi('p-9')).thenAnswer((_) async =>
        Left(NotFoundException(message: 'Riwayat tidak ditemukan')));
    di.registerFactory<RevisiPencairanCubit>(
        () => RevisiPencairanCubit(useCases));
    addTearDown(() => di.unregister<RevisiPencairanCubit>());
    await openSheet(tester, _pencairan(diperbarui: true),
        size: const Size(1200, 900));

    await tapKey(tester, 'riwayat-perubahan-pencairan');

    expect(find.text('revisi p-9'), findsNothing, reason: 'not the route');
    expect(find.byType(Dialog), findsOneWidget, reason: 'the same dialog');
    expect(find.text('Riwayat Perubahan'), findsOneWidget);
    expect(find.text('Riwayat tidak ditemukan'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('a pencairan without a potongan still shows both rows',
      (tester) async {
    await openSheet(tester, _pencairan());

    expect(find.text('Potongan'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    expect(find.text('Dibayar'), findsOneWidget);
  });

  testWidgets('on a wide window the history goes back to the detail',
      (tester) async {
    final useCases = _MockUseCases();
    when(() => useCases.getRevisi('p-9')).thenAnswer((_) async =>
        Left(NotFoundException(message: 'Riwayat tidak ditemukan')));
    di.registerFactory<RevisiPencairanCubit>(
        () => RevisiPencairanCubit(useCases));
    addTearDown(() => di.unregister<RevisiPencairanCubit>());
    await openSheet(tester, _pencairan(diperbarui: true),
        size: const Size(1200, 900));
    await tapKey(tester, 'riwayat-perubahan-pencairan');

    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pencairan'), findsOneWidget);
    expect(find.text('Riwayat tidak ditemukan'), findsNothing);
  });

  testWidgets('on a wide window a saved edit refreshes the caller and closes',
      (tester) async {
    final useCases = _MockUseCases();
    final edited = _pencairan(diperbarui: true);
    when(() => useCases.editPencairan(any()))
        .thenAnswer((_) async => Right(edited));
    di.registerFactory<PencairanUseCases>(() => useCases);
    addTearDown(() => di.unregister<PencairanUseCases>());
    await openSheet(tester, _pencairan(), size: const Size(1200, 900));
    await tapKey(tester, 'edit-pencairan');

    await tester.enterText(find.byKey(const Key('nominal-field')), '100000');
    await tester.enterText(
        find.byKey(const Key('alasan-field')), 'Salah ketik');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('submit-edit-pencairan')));
    await tester.tap(find.byKey(const Key('submit-edit-pencairan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(changes, 1);
    expect(find.byType(Dialog), findsNothing);
  });
}
