import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/pencairan.dart';
import 'package:pilah_mobile/features/pencairan/domain/model/riwayat_pencairan_filter.dart';
import 'package:pilah_mobile/features/pencairan/domain/use_cases/pencairan_use_cases.dart';
import 'package:pilah_mobile/features/pencairan/presentation/blocs/riwayat_pencairan_cubit.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_page.dart';

class _MockUseCases extends Mock implements PencairanUseCases {}

final _now = DateTime(2026, 9, 22, 12);

Pencairan _row(String id, DateTime tanggal, {String nama = 'Ahmad Ridwan'}) =>
    Pencairan(
      id: id,
      nasabahId: 'n-1',
      nasabahNama: nama,
      nominal: 200000,
      metode: MetodePencairan.tunai,
      tanggal: tanggal,
      keterangan: 'Diambil pagi',
      status: 'tercatat',
      saldoSebelum: 465600,
      saldoSesudah: 265600,
      dicatatOlehNama: 'Ibu Sari',
    );

void main() {
  setUpAll(() => registerFallbackValue(const RiwayatPencairanFilter()));

  late _MockUseCases useCases;

  void stubRows(List<Pencairan> rows) {
    when(() => useCases.getRiwayat(any())).thenAnswer((_) async => Right(rows));
  }

  setUp(() {
    useCases = _MockUseCases();
    stubRows([
      _row('p-1', DateTime(2026, 9, 22, 10, 15)),
      _row('p-2', DateTime(2026, 9, 21, 9), nama: 'Siti Aminah'),
    ]);
  });

  Future<void> pumpView(
    WidgetTester tester, {
    String? nasabahId,
    String? nasabahNama,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => RiwayatPencairanCubit(useCases),
          child: RiwayatPencairanView(
            nasabahId: nasabahId,
            nasabahNama: nasabahNama,
            now: () => _now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RiwayatPencairanFilter lastFilter() =>
      verify(() => useCases.getRiwayat(captureAny())).captured.last
          as RiwayatPencairanFilter;

  testWidgets('shows this month for the whole bank, grouped by day',
      (tester) async {
    await pumpView(tester);

    expect(lastFilter(),
        const RiwayatPencairanFilter(periode: RiwayatPeriode.bulanIni));
    expect(find.text('HARI INI'), findsOneWidget);
    expect(find.text('KEMARIN'), findsOneWidget);
    expect(find.text('Ahmad Ridwan'), findsOneWidget);
    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsNWidgets(2));
    expect(find.text('Tunai • 10:15'), findsOneWidget);
    expect(find.text('Diambil pagi'), findsNWidgets(2));
    expect(find.byKey(const Key('riwayat-search')), findsOneWidget);
  });

  testWidgets('shows the whole history of one nasabah', (tester) async {
    await pumpView(tester, nasabahId: 'n-1', nasabahNama: 'Ahmad Ridwan');

    expect(
      lastFilter(),
      const RiwayatPencairanFilter(
        periode: RiwayatPeriode.semua,
        nasabahId: 'n-1',
      ),
    );
    expect(find.text('Riwayat Pencairan · Ahmad Ridwan'), findsOneWidget);
    expect(find.byKey(const Key('riwayat-search')), findsNothing);
  });

  testWidgets('reloads when another periode is chosen', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Bulan Lalu'));
    await tester.pumpAndSettle();

    expect(lastFilter().periode, RiwayatPeriode.bulanLalu);
  });

  testWidgets('reloads with the submitted search', (tester) async {
    await pumpView(tester);

    await tester.enterText(find.byKey(const Key('riwayat-search')), 'siti');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(lastFilter().search, 'siti');
  });

  testWidgets('asks for a second letter instead of searching for one',
      (tester) async {
    await pumpView(tester);
    final before = verify(() => useCases.getRiwayat(captureAny())).captured;

    await tester.enterText(find.byKey(const Key('riwayat-search')), 's');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // The backend ignores a search below 2 characters, which would silently
    // return the whole riwayat; say so rather than sending it.
    expect(find.text('Minimal 2 huruf'), findsOneWidget);
    expect(
      verify(() => useCases.getRiwayat(captureAny())).captured.length,
      before.length,
    );
  });

  testWidgets('clears an active search from the field', (tester) async {
    await pumpView(tester);
    await tester.enterText(find.byKey(const Key('riwayat-search')), 'siti');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('riwayat-search-clear')));
    await tester.pumpAndSettle();

    expect(lastFilter().search, '');
    expect(find.byKey(const Key('riwayat-search-clear')), findsNothing);
  });

  testWidgets('shows the full record when an entry is tapped', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Ahmad Ridwan'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pencairan'), findsOneWidget);
    expect(find.text('Rp 465.600'), findsOneWidget);
    expect(find.text('Rp 265.600'), findsOneWidget);
    expect(find.text('Ibu Sari'), findsOneWidget);
    expect(find.text('Tercatat'), findsWidgets);
  });

  testWidgets('says so when there is nothing to show', (tester) async {
    stubRows(const []);
    await pumpView(tester);

    expect(find.text('Belum ada pencairan'), findsOneWidget);
  });
}
