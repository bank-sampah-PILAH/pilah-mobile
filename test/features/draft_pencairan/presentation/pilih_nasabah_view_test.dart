import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/core/router/root_navigator_key.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/pilih_nasabah_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_editor_args.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/pilih_nasabah_pencairan_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

const _ahmad =
    Kandidat(id: 'n-1', kode: 'NAS-0001', nama: 'Ahmad Ridwan', saldo: 465600);
const _budi =
    Kandidat(id: 'n-2', kode: 'NAS-0002', nama: 'Budi Santoso', saldo: 50000);
const _citra =
    Kandidat(id: 'n-3', kode: 'NAS-0003', nama: 'Citra Dewi', saldo: 250000);

void main() {
  late _MockUseCases useCases;
  Object? openedWith;

  void answer({
    String search = '',
    KandidatUrutan urutan = KandidatUrutan.namaAZ,
    int saldoMin = 0,
    List<Kandidat> rows = const [_ahmad, _budi, _citra],
  }) {
    when(() => useCases.getKandidat(
          search: search,
          urutan: urutan,
          saldoMin: saldoMin,
        )).thenAnswer((_) async => Right(rows));
  }

  setUp(() {
    useCases = _MockUseCases();
    openedWith = null;
    answer();
  });

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => BlocProvider(
            create: (_) => PilihNasabahCubit(useCases)..load(),
            child: const PilihNasabahView(),
          ),
        ),
        GoRoute(
          path: DraftListPage.routeEditor,
          builder: (_, state) {
            openedWith = state.extra;
            return const Scaffold(body: Text('route:editor'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('has the pencairan header with a back button', (tester) async {
    await pump(tester);

    expect(find.byKey(const Key('kembali')), findsOneWidget);
    expect(find.text('Pilih Nasabah'), findsOneWidget);
    expect(find.byType(PencairanChip), findsWidgets,
        reason: 'quick selects are pills');
  });

  testWidgets('lists each nasabah with their code and saldo', (tester) async {
    await pump(tester);

    expect(find.text('Ahmad Ridwan'), findsOneWidget);
    expect(find.textContaining('NAS-0002'), findsOneWidget);
    expect(find.textContaining('Rp 250.000'), findsOneWidget);
    expect(find.text('0 dipilih'), findsOneWidget);
  });

  testWidgets('continue stays off until someone is picked', (tester) async {
    await pump(tester);

    expect(
        tester
            .widget<CustomPrimaryButton>(find.byKey(const Key('lanjut')))
            .onPressed,
        isNull);

    await tester.tap(find.byKey(const Key('kandidat-n-2')));
    await tester.pump();

    expect(find.text('1 dipilih'), findsOneWidget);
    expect(find.textContaining('Rp 50.000'), findsWidgets);
    expect(
        tester
            .widget<CustomPrimaryButton>(find.byKey(const Key('lanjut')))
            .onPressed,
        isNotNull);
  });

  testWidgets('continue hands the picked nasabah to the editor',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('kandidat-n-3')));
    await tester.tap(find.byKey(const Key('kandidat-n-1')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('lanjut')));
    await tester.pumpAndSettle();

    expect(find.text('route:editor'), findsOneWidget);
    expect((openedWith! as DraftEditorArgs).kandidat, [_ahmad, _citra]);
  });

  testWidgets('select all picks everyone and shows their combined saldo',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('pilih-semua')));
    await tester.pumpAndSettle();

    expect(find.text('3 dipilih'), findsOneWidget);
    expect(find.textContaining('Rp 765.600'), findsOneWidget);
  });

  testWidgets('clear drops every pick', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('kandidat-n-1')));
    await tester.pump();
    expect(find.text('1 dipilih'), findsOneWidget);

    await tester.tap(find.byKey(const Key('kosongkan')));
    await tester.pump();

    expect(find.text('0 dipilih'), findsOneWidget);
  });

  testWidgets('searching waits for a pause in typing, then asks the server',
      (tester) async {
    answer(search: 'bud', rows: const [_budi]);
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'b');
    await tester.enterText(find.byType(TextField), 'bud');
    await tester.pump(const Duration(milliseconds: 100));
    verifyNever(() => useCases.getKandidat(
        search: 'bud', urutan: KandidatUrutan.namaAZ, saldoMin: 0));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    verify(() => useCases.getKandidat(
        search: 'bud', urutan: KandidatUrutan.namaAZ, saldoMin: 0)).called(1);
    expect(find.text('Ahmad Ridwan'), findsNothing);
    expect(find.text('Budi Santoso'), findsOneWidget);
  });

  testWidgets('the sort menu offers name and saldo, both directions',
      (tester) async {
    answer(
        urutan: KandidatUrutan.saldoTerbesar,
        rows: const [_ahmad, _citra, _budi]);
    await pump(tester);

    await tester.tap(find.byKey(const Key('urutan')));
    await tester.pumpAndSettle();
    for (final label in [
      'Nama A-Z',
      'Nama Z-A',
      'Saldo terkecil',
      'Saldo terbesar'
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Saldo terbesar').last);
    await tester.pumpAndSettle();

    verify(() => useCases.getKandidat(
        search: '',
        urutan: KandidatUrutan.saldoTerbesar,
        saldoMin: 0)).called(1);
  });

  testWidgets('says so when nobody can be paid out', (tester) async {
    answer(rows: const []);
    await pump(tester);

    expect(find.text('Tidak ada nasabah yang dapat dicairkan'), findsOneWidget);
  });
}
