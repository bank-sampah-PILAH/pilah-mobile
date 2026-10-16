import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

Future<void> _pumpAt(WidgetTester tester, Size size) async {
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
      child: const MaterialApp(home: JadwalPage()),
    ),
  );
  await tester.pump();
}

/// The form is the same form on both platforms; only its container changes.
/// On a phone it stays the modal bottom sheet it already was. In a browser
/// window it becomes a panel beside the agenda, so the day being scheduled
/// into stays visible while it is filled in.
void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

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
