import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/features/draft_pencairan/domain/use_cases/draft_pencairan_use_cases.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/blocs/draft_list_cubit.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/pages/draft_list_page.dart';
import 'package:pilah_mobile/features/draft_pencairan/presentation/widgets/pencairan_ui.dart';

import '../../../support/pump_app.dart';

class _MockUseCases extends Mock implements DraftPencairanUseCases {}

DraftRingkasan _draft(String id, String nama, DraftStatus status) =>
    DraftRingkasan(
      id: id,
      nama: nama,
      status: status,
      dibuatOlehNama: 'Ibu Sari',
      createdAt: DateTime(2026, 10, 7, 9, 5),
      jumlahItem: 3,
      totalNominal: 150000,
      totalPotongan: 11500,
      totalDibayar: 138500,
    );

void main() {
  late _MockUseCases useCases;

  setUp(() => useCases = _MockUseCases());

  Future<GoRouter> pump(
    WidgetTester tester,
    List<DraftRingkasan> drafts,
  ) async {
    when(() => useCases.getDrafts()).thenAnswer((_) async => Right(drafts));
    return pumpRouted(
      tester,
      BlocProvider(
        create: (_) => DraftListCubit(useCases)..load(),
        child: const DraftListView(),
      ),
      extraRoutes: const [
        DraftListPage.routePilih,
        DraftListPage.routeEditor,
        '/catat-pencairan',
      ],
    );
  }

  testWidgets('has the pencairan header with a back button and pill filters',
      (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kembali')), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.byType(PencairanChip), findsNWidgets(4));
  });

  testWidgets('shows each draft with its status, size, total and who made it',
      (tester) async {
    await pump(tester, [
      _draft('d-1', 'Cair Oktober', DraftStatus.draft),
      _draft('d-2', 'Cair September', DraftStatus.dikonfirmasi),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsOneWidget);
    expect(find.text('Cair September'), findsOneWidget);
    expect(find.text('Draft'), findsWidgets);
    expect(find.text('Dikonfirmasi'), findsWidgets);
    expect(find.textContaining('3 nasabah'), findsNWidgets(2));
    expect(find.textContaining('Rp 138.500'), findsNWidgets(2));
    expect(find.textContaining('Ibu Sari'), findsNWidgets(2));
    expect(find.textContaining('7 Okt 2026'), findsNWidgets(2));
  });

  testWidgets('a status chip narrows the list', (tester) async {
    await pump(tester, [
      _draft('d-1', 'Cair Oktober', DraftStatus.draft),
      _draft('d-2', 'Cair September', DraftStatus.dikonfirmasi),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filter-dikonfirmasi')));
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsNothing);
    expect(find.text('Cair September'), findsOneWidget);

    await tester.tap(find.byKey(const Key('filter-semua')));
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsOneWidget);
  });

  testWidgets('says so when there are no drafts yet', (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada draft pencairan'), findsOneWidget);
  });

  testWidgets('a failed load can be retried', (tester) async {
    when(() => useCases.getDrafts())
        .thenAnswer((_) async => Left(ConnectionTimeOutException()));
    await pumpRouted(
      tester,
      BlocProvider(
        create: (_) => DraftListCubit(useCases)..load(),
        child: const DraftListView(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);

    when(() => useCases.getDrafts()).thenAnswer(
        (_) async => Right([_draft('d-1', 'Cair Oktober', DraftStatus.draft)]));
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Cair Oktober'), findsOneWidget);
  });

  testWidgets('the add button starts picking nasabah', (tester) async {
    await pump(tester, const []);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buat Pencairan'));
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routePilih}'), findsOneWidget);
  });

  testWidgets('opening a draft goes to the editor', (tester) async {
    await pump(tester, [_draft('d-1', 'Cair Oktober', DraftStatus.draft)]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cair Oktober'));
    await tester.pumpAndSettle();

    expect(find.text('route:${DraftListPage.routeEditor}'), findsOneWidget);
  });
}
