import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/states/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_upcoming_months.dart';
import 'package:pilah_mobile/features/jadwal/presentation/providers/jadwal_provider.dart';
import '../../../../support/jadwal_provider_support.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';

class _JadwalCalls {
  final agendaLoads = <({bool silent, DateTime? date, DateTime? dateTo})>[];
  final calendarLoads = <(DateTime, DateTime)>[];
  final saves = <JadwalEntity>[];
  int upcomingLoads = 0;
}

/// Opens the create form: the page action in an expanded window, the floating
/// button below it.
Future<void> _tapCreate(WidgetTester tester) async {
  final fab = find.byTooltip('Buat Jadwal');
  await tester.tap(fab.evaluate().isNotEmpty
      ? fab
      : find.widgetWithText(AppButton, 'Buat Jadwal'));
}

Future<_JadwalCalls> _pumpAt(
  WidgetTester tester,
  Size size, {
  DateTime? initialDate,
  JadwalLoaded state = const JadwalLoaded([]),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final calls = _JadwalCalls();
  final notifier = TestJadwalNotifier(
    repository: UnusedJadwalRepository(),
    initialState: state,
    onLoadJadwal: (
        {bool silent = false, DateTime? date, DateTime? dateTo}) async {
      calls.agendaLoads.add((silent: silent, date: date, dateTo: dateTo));
    },
    onLoadCalendarDates: ({required startDate, required endDate}) async {
      calls.calendarLoads.add((startDate, endDate));
    },
    onLoadUpcomingDates: ({today}) async => calls.upcomingLoads++,
    onSaveJadwal: (schedule) async {
      calls.saves.add(schedule);
      return null;
    },
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [jadwalProvider.overrideWith(() => notifier)],
      child: MaterialApp(home: JadwalPage(initialDate: initialDate)),
    ),
  );
  await tester.pump();
  return calls;
}

/// The form is the same form on both platforms; only its container changes.
/// On a phone it stays the modal bottom sheet it already was. In a browser
/// window it becomes a panel beside the agenda, so the day being scheduled
/// into stays visible while it is filled in.
void main() {
  testWidgets('on a desktop window the title is a page header, not an AppBar',
      (tester) async {
    await _pumpAt(tester, const Size(1000, 900));

    expect(find.byType(AppBar), findsNothing);
    expect(tester.getTopLeft(find.text('Jadwal Kegiatan')).dx, 32);
  });

  testWidgets('on a wide window the calendar sits beside the agenda',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    final calendar = tester.getRect(find.byType(JadwalCalendar));
    final agenda = tester.getRect(find.text('0 jadwal'));
    expect(calendar.width, lessThanOrEqualTo(440));
    expect(agenda.left, greaterThan(calendar.right));
    expect(agenda.top, lessThan(calendar.bottom));
    expect(
      find.byKey(const ValueKey('jadwal-calendar-toggle')),
      findsNothing,
      reason: 'a side calendar is always the whole month',
    );
  });

  testWidgets(
      'on a very wide window the agenda scrolls across the window, so its '
      'scrollbar sits at the edge', (tester) async {
    await _pumpAt(tester, const Size(1920, 900));

    final scroll = find.descendant(
      of: find.byType(JadwalPage),
      matching: find.byType(ListView),
    );
    expect(tester.getRect(scroll.first).right, 1920);
    // The content still stays within the 1200 column: the title and the
    // calendar start at the column's edge plus the gutter.
    expect(tester.getTopLeft(find.text('Jadwal Kegiatan')).dx, 360 + 32);
    expect(tester.getTopLeft(find.byType(JadwalCalendar)).dx, 360 + 32);
  });

  testWidgets('a narrower window stacks the agenda under the calendar',
      (tester) async {
    await _pumpAt(tester, const Size(860, 900));

    final calendar = tester.getRect(find.byType(JadwalCalendar));
    final agenda = tester.getRect(find.text('0 jadwal'));
    expect(agenda.top, greaterThan(calendar.bottom));
    expect(
      find.byKey(const ValueKey('jadwal-calendar-toggle')),
      findsOneWidget,
    );
  });

  testWidgets('opening the form stacks the agenda so the panel has room',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    final calendar = tester.getRect(find.byType(JadwalCalendar));
    final agenda = tester.getRect(find.text('0 jadwal'));
    expect(agenda.top, greaterThan(calendar.bottom));
  });

  testWidgets(
      'an expanded window creates from the header, not a floating button',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.widgetWithText(AppButton, 'Buat Jadwal'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Buat Jadwal'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);
  });

  testWidgets('a medium window and a phone keep the floating button',
      (tester) async {
    await _pumpAt(tester, const Size(700, 900));

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Buat Jadwal'), findsNothing);
  });

  testWidgets('the calendar stays put while a long agenda scrolls',
      (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final items = [
      for (var i = 0; i < 20; i++)
        JadwalEntity(
          id: 'j-$i',
          bankSampahId: 'b',
          jenisKegiatan: 'penimbangan',
          mulaiPada: today.add(Duration(hours: 8, minutes: i)),
          selesaiPada: today.add(Duration(hours: 10, minutes: i)),
          lokasi: 'Balai $i',
        ),
    ];
    await _pumpAt(
      tester,
      const Size(1440, 900),
      state: JadwalLoaded(items, totalCount: 20, scheduledDates: {today}),
    );
    final before = tester.getTopLeft(find.byType(JadwalCalendar));

    await tester.drag(find.text('Balai 0'), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Balai 0').hitTestable(), findsNothing);
    expect(tester.getTopLeft(find.byType(JadwalCalendar)), before);
  });

  testWidgets('the later months sit under the calendar and open the month',
      (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final later = DateTime(today.year, today.month + 1, 5);
    final calls = await _pumpAt(
      tester,
      const Size(1440, 900),
      state: JadwalLoaded(const [], upcomingDates: {today, later}),
    );

    expect(find.text('Berikutnya'), findsOneWidget);
    expect(find.text('Bulan ini'), findsOneWidget);
    expect(find.text('1 hari berjadwal'), findsNWidgets(2));
    final calendar = tester.getRect(find.byType(JadwalCalendar));
    expect(tester.getTopLeft(find.text('Berikutnya')).dy,
        greaterThan(calendar.bottom));

    await tester.tap(find
        .descendant(
          of: find.byType(JadwalUpcomingMonths),
          matching: find.byType(InkWell),
        )
        .last);
    await tester.pump();

    expect(
      calls.agendaLoads.where((call) =>
          call.date == later &&
          call.dateTo == DateTime(later.year, later.month + 1, 0)),
      hasLength(1),
    );
  });

  testWidgets('the month summary is as wide as the calendar above it',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    final calendar = tester.getRect(find.byType(JadwalCalendar));
    final next = tester.getRect(find.byType(JadwalUpcomingMonths));
    expect(next.width, calendar.width);
    expect(next.left, calendar.left);
  });

  testWidgets('the empty-day button does not stretch across a wide agenda',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    final button = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Buat Jadwal'),
    );
    expect(button, findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Buat Jadwal')).width,
      lessThanOrEqualTo(280),
    );
  });

  testWidgets('opening the page also loads the upcoming dates', (tester) async {
    final calls = await _pumpAt(tester, const Size(1440, 900));

    expect(calls.upcomingLoads, 1);
  });

  testWidgets('an expanded window loads the agenda to the end of the month',
      (tester) async {
    final calls = await _pumpAt(
      tester,
      const Size(1440, 900),
      initialDate: DateTime(2026, 10, 19),
    );

    expect(
      calls.agendaLoads.where((call) =>
          call.date == DateTime(2026, 10, 19) &&
          call.dateTo == DateTime(2026, 10, 31)),
      hasLength(1),
    );
  });

  testWidgets('pulling the agenda down reloads the range without clearing it',
      (tester) async {
    final calls = await _pumpAt(
      tester,
      const Size(1440, 900),
      initialDate: DateTime(2026, 10, 19),
    );

    await tester.fling(find.byType(ListView).last, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(
      calls.agendaLoads.where((call) =>
          call.silent &&
          call.date == DateTime(2026, 10, 19) &&
          call.dateTo == DateTime(2026, 10, 31)),
      hasLength(1),
    );
  });

  testWidgets('a medium window and a phone keep a one-day agenda',
      (tester) async {
    final calls = await _pumpAt(
      tester,
      const Size(700, 900),
      initialDate: DateTime(2026, 10, 19),
    );

    expect(
      calls.agendaLoads.where(
          (call) => call.date == DateTime(2026, 10, 19) && call.dateTo == null),
      hasLength(1),
    );
    expect(calls.agendaLoads.where((call) => call.dateTo != null), isEmpty);
  });

  testWidgets('widening to expanded reloads the agenda as a range',
      (tester) async {
    final calls = await _pumpAt(
      tester,
      const Size(700, 900),
      initialDate: DateTime(2026, 10, 19),
    );

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pump();

    expect(
      calls.agendaLoads.where((call) =>
          call.date == DateTime(2026, 10, 19) &&
          call.dateTo == DateTime(2026, 10, 31)),
      hasLength(1),
    );
  });

  testWidgets('the agenda groups the rest of the month by day', (tester) async {
    JadwalEntity at(String id, int day, String lokasi) => JadwalEntity(
          id: id,
          bankSampahId: 'b',
          jenisKegiatan: 'penimbangan',
          mulaiPada: DateTime(2026, 10, day, 9),
          selesaiPada: DateTime(2026, 10, day, 11),
          lokasi: lokasi,
        );
    await _pumpAt(
      tester,
      const Size(1440, 900),
      initialDate: DateTime(2026, 10, 19),
      state: JadwalLoaded([
        at('a', 19, 'Balai Satu'),
        at('b', 19, 'Balai Dua'),
        at('c', 23, 'Balai Tiga'),
      ], totalCount: 3),
    );

    // "Hari ini, " prefixes whichever heading is today.
    expect(find.textContaining('Senin, 19 Oktober'), findsOneWidget);
    expect(find.textContaining('Jumat, 23 Oktober'), findsOneWidget);
    expect(find.text('2 jadwal'), findsOneWidget);
    expect(find.text('1 jadwal'), findsOneWidget);
    for (final lokasi in ['Balai Satu', 'Balai Dua', 'Balai Tiga']) {
      expect(find.text(lokasi), findsOneWidget);
    }
    expect(
      tester.getTopLeft(find.textContaining('Senin, 19 Oktober')).dy,
      lessThan(tester.getTopLeft(find.text('Balai Tiga')).dy),
    );
  });

  testWidgets('a selected day without schedules still gets its own heading',
      (tester) async {
    await _pumpAt(
      tester,
      const Size(1440, 900),
      initialDate: DateTime(2026, 10, 19),
      state: JadwalLoaded([
        JadwalEntity(
          id: 'c',
          bankSampahId: 'b',
          jenisKegiatan: 'penimbangan',
          mulaiPada: DateTime(2026, 10, 23, 9),
          selesaiPada: DateTime(2026, 10, 23, 11),
          lokasi: 'Balai Tiga',
        ),
      ], totalCount: 1),
    );

    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    expect(find.textContaining('Jumat, 23 Oktober'), findsOneWidget);
    expect(find.text('Balai Tiga'), findsOneWidget);
  });

  testWidgets('on a phone the title stays in the AppBar', (tester) async {
    await _pumpAt(tester, const Size(420, 900));

    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('on a desktop window the form opens as a panel, not a sheet',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);
    expect(
      find.byType(BottomSheet),
      findsNothing,
      reason: 'a panel must not also be hosted in a sheet',
    );
  });

  testWidgets('the panel closes itself when its close button is tapped',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('jadwal-form')),
      findsNothing,
      reason: 'a panel is not on a route, so it cannot be dismissed by a pop',
    );
  });

  testWidgets('navigating a month clamps to the last day of a shorter month',
      (tester) async {
    await _pumpAt(
      tester,
      const Size(1440, 900),
      initialDate: DateTime(2026, 1, 31),
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('28 Februari'),
      findsWidgets,
      reason: 'without the clamp DateTime(2026, 2, 31) rolls over to 3 Maret',
    );
  });

  testWidgets('saving from the panel closes it', (tester) async {
    final calls = await _pumpAt(tester, const Size(1440, 900));

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lokasi'),
      'Balai RW 04',
    );
    await tester.tap(find.text('Simpan Jadwal'));
    await tester.pumpAndSettle();

    expect(calls.saves, hasLength(1));
    expect(
      find.byKey(const ValueKey('jadwal-form')),
      findsNothing,
      reason: 'a saved schedule should hand the agenda back its full width',
    );
  });

  testWidgets('at exactly the expanded boundary the form opens as a panel',
      (tester) async {
    await _pumpAt(tester, const Size(840, 900));

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(
      find.byType(BottomSheet),
      findsNothing,
      reason: '840 is expandedMinWidth, so it is already expanded',
    );
  });

  testWidgets('one pixel below expanded the form is a dialog, not a panel',
      (tester) async {
    await _pumpAt(tester, const Size(839, 900));

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(
      find.byType(Dialog),
      findsOneWidget,
      reason: 'a 2/5 panel at medium is about 320px, too narrow for this form',
    );
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('on a phone the form still opens as a bottom sheet',
      (tester) async {
    await _pumpAt(tester, const Size(390, 844));

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);
    expect(
      find.byType(BottomSheet),
      findsOneWidget,
      reason: 'compact behaviour must be left exactly as it was',
    );
  });

  // The container is chosen when the form opens, but the window can be resized
  // afterwards. These cover the shrink, which used to leave the panel in widths
  // the open path deliberately avoids.
  testWidgets(
      'shrinking to medium closes the open panel rather than '
      'narrowing it', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));
    await _tapCreate(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('jadwal-form')),
      findsNothing,
      reason: 'a 2/5 panel at medium is the width the open path refuses',
    );
  });

  testWidgets('shrinking to compact closes the open panel', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));
    await _tapCreate(tester);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('jadwal-form')),
      findsNothing,
      reason: 'MasterDetailLayout drops the detail at compact anyway; the page '
          'must not keep believing a panel is open',
    );
  });

  testWidgets(
      'after shrinking, the add button gives a sheet and no stale panel',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));
    await _tapCreate(tester);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    await _tapCreate(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);
    expect(
      find.byType(BottomSheet),
      findsOneWidget,
      reason: 'the reopened form belongs in the container for the new width',
    );
  });

  testWidgets('widening past expanded does not resurrect a closed panel',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));
    await _tapCreate(tester);
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('jadwal-form')),
      findsNothing,
      reason: 'a blank form reappearing on resize reads as a bug; the panel is '
          'closed, and reopening it is the user\'s call',
    );
  });
}
