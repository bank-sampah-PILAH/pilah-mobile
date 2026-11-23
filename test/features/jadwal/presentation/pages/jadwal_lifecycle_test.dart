import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import 'package:pilah_mobile/features/jadwal/presentation/states/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import '../../../../support/jadwal_provider_support.dart';

Widget _app(JadwalNotifier notifier) => ProviderScope(
      overrides: [jadwalProvider.overrideWith(() => notifier)],
      child: const MaterialApp(home: JadwalPage()),
    );

TestJadwalNotifier _testNotifier(
  JadwalState state, {
  Future<NetworkException?> Function(String id, String action)? onChangeStatus,
}) =>
    TestJadwalNotifier(
      repository: UnusedJadwalRepository(),
      initialState: state,
      onChangeStatus: onChangeStatus,
    );

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

  testWidgets('draft schedule can be published from the management list',
      (tester) async {
    final changes = <(String, String)>[];
    final schedule = _schedule(status: 'draft');
    await tester.pumpWidget(_app(_testNotifier(
      JadwalLoaded([schedule]),
      onChangeStatus: (id, action) async {
        changes.add((id, action));
        return null;
      },
    )));
    await tester.pump();

    expect(find.text('Terbitkan'), findsOneWidget);
    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    expect(changes, [('jadwal-1', 'terbitkan')]);
  });

  testWidgets('draft schedule confirms cancellation before transitioning',
      (tester) async {
    final changes = <(String, String)>[];
    await tester.pumpWidget(_app(_testNotifier(
      JadwalLoaded([_schedule(status: 'draft')]),
      onChangeStatus: (id, action) async {
        changes.add((id, action));
        return null;
      },
    )));
    await tester.pump();

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(changes, isEmpty);

    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();

    expect(changes, [('jadwal-1', 'batalkan')]);
  });

  testWidgets('published schedule confirms cancellation and reports failures',
      (tester) async {
    final changes = <(String, String)>[];
    final schedule = _schedule(status: 'diterbitkan');
    await tester.pumpWidget(_app(_testNotifier(
      JadwalLoaded([schedule]),
      onChangeStatus: (id, action) async {
        changes.add((id, action));
        return GeneralException(message: 'offline');
      },
    )));
    await tester.pump();

    expect(find.text('Batalkan'), findsOneWidget);
    expect(find.text('Tandai Selesai'), findsOneWidget);
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Ya, batalkan'), findsOneWidget);
    expect(changes, isEmpty);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, batalkan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(changes, [('jadwal-1', 'batalkan')]);
    expect(find.text('offline'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('published schedule confirms completion before transitioning',
      (tester) async {
    final changes = <(String, String)>[];
    await tester.pumpWidget(_app(_testNotifier(
      JadwalLoaded([_schedule(status: 'diterbitkan')]),
      onChangeStatus: (id, action) async {
        changes.add((id, action));
        return null;
      },
    )));
    await tester.pump();

    await tester.tap(find.text('Tandai Selesai'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Ya, selesaikan'), findsOneWidget);
    expect(changes, isEmpty);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    await tester.tap(find.text('Tandai Selesai'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, selesaikan'));
    await tester.pumpAndSettle();

    expect(changes, [('jadwal-1', 'selesaikan')]);
  });

  testWidgets('disables lifecycle actions during a pending transition',
      (tester) async {
    final repository = _MockJadwalRepository();
    final schedule = _schedule(status: 'draft');
    final transition = Completer<Either<NetworkException, JadwalEntity>>();
    when(
      () => repository.getJadwal(
        page: 1,
        date: DateUtils.dateOnly(DateTime.now()),
      ),
    ).thenAnswer((_) async => Right(_page([schedule])));
    when(() => repository.getCalendarDates(any(), any()))
        .thenAnswer((_) async => const Right(<DateTime>{}));
    when(() => repository.transition('jadwal-1', 'terbitkan'))
        .thenAnswer((_) => transition.future);
    final cubit = JadwalNotifier(repository);

    await tester.pumpWidget(
      ProviderScope(
          overrides: [jadwalProvider.overrideWith(() => cubit)],
          child: const MaterialApp(home: JadwalPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Terbitkan'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Batalkan'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Terbitkan'), warnIfMissed: false);
    verify(() => repository.transition('jadwal-1', 'terbitkan')).called(1);

    transition.complete(Right(schedule));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Terbitkan'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('disables lifecycle actions while a schedule save is pending',
      (tester) async {
    final repository = _MockJadwalRepository();
    final schedule = _schedule(status: 'draft');
    final save = Completer<Either<NetworkException, JadwalEntity>>();
    when(
      () => repository.getJadwal(
        page: 1,
        date: DateUtils.dateOnly(DateTime.now()),
      ),
    ).thenAnswer((_) async => Right(_page([schedule])));
    when(() => repository.getCalendarDates(any(), any()))
        .thenAnswer((_) async => const Right(<DateTime>{}));
    when(() => repository.updateJadwal(schedule))
        .thenAnswer((_) => save.future);
    final cubit = JadwalNotifier(repository);

    await tester.pumpWidget(
      ProviderScope(
          overrides: [jadwalProvider.overrideWith(() => cubit)],
          child: const MaterialApp(home: JadwalPage())),
    );
    await tester.pumpAndSettle();

    final saveResult = cubit.saveJadwal(schedule);
    await tester.pumpAndSettle();

    expect(
        cubit.state, JadwalLoaded([schedule], isSaving: true, totalCount: 1));
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Terbitkan'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Batalkan'))
          .onPressed,
      isNull,
    );

    save.complete(Right(schedule));
    expect(await saveResult, isNull);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Terbitkan'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('prevents opening a schedule form during a transition',
      (tester) async {
    final repository = _MockJadwalRepository();
    final schedule = _schedule(status: 'draft');
    final transition = Completer<Either<NetworkException, JadwalEntity>>();
    when(
      () => repository.getJadwal(
        page: 1,
        date: DateUtils.dateOnly(DateTime.now()),
      ),
    ).thenAnswer((_) async => Right(_page([schedule])));
    when(() => repository.getCalendarDates(any(), any()))
        .thenAnswer((_) async => const Right(<DateTime>{}));
    when(() => repository.transition('jadwal-1', 'terbitkan'))
        .thenAnswer((_) => transition.future);
    final cubit = JadwalNotifier(repository);

    await tester.pumpWidget(
      ProviderScope(
          overrides: [jadwalProvider.overrideWith(() => cubit)],
          child: const MaterialApp(home: JadwalPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terbitkan'));
    await tester.pump();

    final fabFinder = find.byType(FloatingActionButton);
    expect(tester.widget<FloatingActionButton>(fabFinder).onPressed, isNull);
    await tester.tap(fabFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Buat Jadwal'), findsNothing);

    transition.complete(Right(schedule));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FloatingActionButton>(fabFinder).onPressed,
      isNotNull,
    );
  });
}

class _MockJadwalRepository extends Mock implements JadwalRepository {}

JadwalPageResult _page(List<JadwalEntity> items) =>
    JadwalPageResult(items: items, totalCount: items.length, hasMore: false);

JadwalEntity _schedule({required String status}) {
  final today = DateUtils.dateOnly(DateTime.now());
  return JadwalEntity(
    id: 'jadwal-1',
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: today.add(const Duration(hours: 9)),
    selesaiPada: today.add(const Duration(hours: 11)),
    lokasi: 'Balai Warga',
    status: status,
  );
}
