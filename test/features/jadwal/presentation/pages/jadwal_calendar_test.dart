import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

void main() {
  testWidgets('selecting a marked date shows its agenda and prefills creation',
      (
    tester,
  ) async {
    final cubit = _MockJadwalCubit();
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, 10);
    final schedule = _schedule(scheduledDate);
    when(() => cubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Penimbangan Sampah'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('jadwal-calendar-toggle')));
    await tester.pumpAndSettle();

    final dateKey = ValueKey(
      'jadwal-date-${scheduledDate.year}-${scheduledDate.month}-${scheduledDate.day}',
    );
    final dateCell = find.byKey(dateKey);
    expect(dateCell, findsOneWidget);
    expect(
      find.byKey(
        ValueKey(
          'jadwal-marker-${scheduledDate.year}-${scheduledDate.month}-${scheduledDate.day}',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(dateCell);
    await tester.pumpAndSettle();

    expect(find.text('Penimbangan Sampah'), findsOneWidget);
    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.text('Draf'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Buat Jadwal'), findsOneWidget);
    final datePrefix = '${scheduledDate.day.toString().padLeft(2, '0')}/'
        '${scheduledDate.month.toString().padLeft(2, '0')}/'
        '${scheduledDate.year}';
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('jadwal-mulai')),
        matching: find.byWidgetPredicate(
          (widget) => widget is Text && widget.data!.startsWith(datePrefix),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty selected date offers a create action', (tester) async {
    final cubit = _MockJadwalCubit();
    when(() => cubit.state).thenReturn(const JadwalLoaded([]));
    when(() => cubit.loadJadwal()).thenAnswer((_) async {});

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    final createButton = find.widgetWithText(FilledButton, 'Buat Jadwal');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('jadwal-form')),
        matching: find.text('Buat Jadwal'),
      ),
      findsOneWidget,
    );
  });
}

JadwalEntity _schedule(DateTime date) => JadwalEntity(
      id: 'schedule-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime(date.year, date.month, date.day, 9),
      selesaiPada: DateTime(date.year, date.month, date.day, 11),
      lokasi: 'Balai Warga',
    );
