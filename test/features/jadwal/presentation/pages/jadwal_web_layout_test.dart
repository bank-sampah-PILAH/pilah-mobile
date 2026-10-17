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

void _stubManagerLoads(_MockJadwalCubit cubit) {
  when(() => cubit.loadJadwal(date: any(named: 'date')))
      .thenAnswer((_) async {});
  when(
    () => cubit.loadCalendarDates(
      startDate: any(named: 'startDate'),
      endDate: any(named: 'endDate'),
    ),
  ).thenAnswer((_) async {});
}

Future<_MockJadwalCubit> _pumpAt(
  WidgetTester tester,
  Size size, {
  DateTime? initialDate,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final cubit = _MockJadwalCubit();
  when(() => cubit.state).thenReturn(const JadwalLoaded([]));
  _stubManagerLoads(cubit);

  await tester.pumpWidget(
    BlocProvider<JadwalCubit>.value(
      value: cubit,
      child: MaterialApp(home: JadwalPage(initialDate: initialDate)),
    ),
  );
  await tester.pump();
  return cubit;
}

/// The form is the same form on both platforms; only its container changes.
/// On a phone it stays the modal bottom sheet it already was. In a browser
/// window it becomes a panel beside the agenda, so the day being scheduled
/// into stays visible while it is filled in.
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(
      JadwalEntity(
        id: '',
        bankSampahId: '',
        jenisKegiatan: 'penimbangan',
        mulaiPada: DateTime(2000),
        selesaiPada: DateTime(2000),
        lokasi: '',
      ),
    );
  });

  testWidgets('on a desktop window the form opens as a panel, not a sheet',
      (tester) async {
    await _pumpAt(tester, const Size(1440, 900));

    await tester.tap(find.byTooltip('Buat Jadwal'));
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

    await tester.tap(find.byTooltip('Buat Jadwal'));
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

    await tester.tap(find.byKey(const ValueKey('jadwal-calendar-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('28 Februari'),
      findsWidgets,
      reason: 'without the clamp DateTime(2026, 2, 31) rolls over to 3 Maret',
    );
  });

  testWidgets('saving from the panel closes it', (tester) async {
    final cubit = await _pumpAt(tester, const Size(1440, 900));
    when(() => cubit.saveJadwal(any())).thenAnswer((_) async => null);

    await tester.tap(find.byTooltip('Buat Jadwal'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lokasi'),
      'Balai RW 04',
    );
    await tester.tap(find.text('Simpan Jadwal'));
    await tester.pumpAndSettle();

    verify(() => cubit.saveJadwal(any())).called(1);
    expect(
      find.byKey(const ValueKey('jadwal-form')),
      findsNothing,
      reason: 'a saved schedule should hand the agenda back its full width',
    );
  });

  testWidgets('at exactly the expanded boundary the form opens as a panel',
      (tester) async {
    await _pumpAt(tester, const Size(840, 900));

    await tester.tap(find.byTooltip('Buat Jadwal'));
    await tester.pumpAndSettle();

    expect(
      find.byType(BottomSheet),
      findsNothing,
      reason: '840 is expandedMinWidth, so it is already expanded',
    );
  });

  testWidgets('one pixel below expanded the form stays a sheet',
      (tester) async {
    await _pumpAt(tester, const Size(839, 900));

    await tester.tap(find.byTooltip('Buat Jadwal'));
    await tester.pumpAndSettle();

    expect(
      find.byType(BottomSheet),
      findsOneWidget,
      reason: 'a 2/5 panel at medium is about 320px, too narrow for this form',
    );
  });

  testWidgets('on a phone the form still opens as a bottom sheet',
      (tester) async {
    await _pumpAt(tester, const Size(390, 844));

    await tester.tap(find.byTooltip('Buat Jadwal'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('jadwal-form')), findsOneWidget);
    expect(
      find.byType(BottomSheet),
      findsOneWidget,
      reason: 'compact behaviour must be left exactly as it was',
    );
  });
}
