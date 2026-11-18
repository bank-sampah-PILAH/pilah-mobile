import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/states/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import '../../../../support/jadwal_provider_support.dart';

void main() {
  testWidgets('selecting a marked date shows its agenda and prefills creation',
      (tester) async {
    final now = DateTime.now();
    // Never today: today is selected already, which is not what is under test.
    final scheduledDate =
        DateTime(now.year, now.month, now.day == 10 ? 11 : 10);
    final schedule = _schedule(scheduledDate);

    await tester.pumpWidget(
      _provideJadwal(
        JadwalLoaded(
          [schedule],
          totalCount: 1,
          scheduledDates: {scheduledDate},
        ),
        const MaterialApp(home: JadwalPage()),
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
    await tester.pumpWidget(
      _provideJadwal(
        const JadwalLoaded([]),
        const MaterialApp(home: JadwalPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    final createButton = find.widgetWithText(ElevatedButton, 'Buat Jadwal');
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

Widget _provideJadwal(JadwalState state, Widget child) => ProviderScope(
      overrides: [
        jadwalProvider.overrideWith(
          () => TestJadwalNotifier(
            repository: UnusedJadwalRepository(),
            initialState: state,
          ),
        ),
      ],
      child: child,
    );

JadwalEntity _schedule(DateTime date) => JadwalEntity(
      id: 'schedule-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: DateTime(date.year, date.month, date.day, 9),
      selesaiPada: DateTime(date.year, date.month, date.day, 11),
      lokasi: 'Balai Warga',
    );
