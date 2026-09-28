import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/router/app_router_config.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';
import '../../support/approved_membership.dart';

class _MockAuthenticationBloc
    extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {}

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
  });

  testWidgets('unknown roles fail closed on the jadwal route', (tester) async {
    if (di.isRegistered<NasabahRepository>()) {
      di.unregister<NasabahRepository>();
    }
    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    addTearDown(() => di.unregister<NasabahRepository>());
    final approval = registerApprovedMembership();
    addTearDown(() => unregisterApprovedMembership(approval));

    final authenticationBloc = _MockAuthenticationBloc();
    final authenticationStates = StreamController<AuthenticationStates>();
    addTearDown(authenticationStates.close);
    final jadwalCubit = _MockJadwalCubit();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = today.add(const Duration(days: 2));
    final dateParam = '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
    final startsAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
    ).toUtc();
    final schedule = JadwalEntity(
      id: 'jadwal-1',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'penimbangan',
      mulaiPada: startsAt,
      selesaiPada: startsAt.add(const Duration(hours: 2)),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );
    whenListen(
      authenticationBloc,
      authenticationStates.stream,
      initialState: AuthenticationLoading(),
    );
    when(() => jadwalCubit.state).thenReturn(JadwalLoaded([schedule]));
    when(() => jadwalCubit.loadJadwal(date: today)).thenAnswer((_) async {});
    when(() => jadwalCubit.loadNextPage()).thenAnswer((_) async {});
    when(() => jadwalCubit.loadJadwal(date: selectedDate))
        .thenAnswer((_) async {});
    _stubCalendarLoad(jadwalCubit, today);
    _stubCalendarLoad(jadwalCubit, selectedDate);

    final router = AppRouterConfig.getRouter();
    router.go('${JadwalPage.route}?date=$dateParam');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthenticationBloc>.value(value: authenticationBloc),
          BlocProvider<JadwalCubit>.value(value: jadwalCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Jadwal Kegiatan'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    for (final role in <String?>[null, 'unknown-role']) {
      authenticationStates.add(
        Authenticated(
          authEntity: AuthEntity(
            id: 'nasabah-1',
            name: 'Nasabah',
            email: 'nasabah@example.com',
            photoUrl: '',
            token: 'token',
            role: role,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Silakan masuk sebagai nasabah.'), findsOneWidget);
      expect(find.text('Jadwal Bank Sampah'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Batalkan'), findsNothing);
      expect(find.text('Terbitkan'), findsNothing);
      expect(find.text('Tandai Selesai'), findsNothing);
    }

    authenticationStates.add(
      Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Nasabah',
          email: 'nasabah@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );
    await tester.pumpAndSettle();
    router.go('${JadwalPage.route}?date=$dateParam');
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Bank Sampah'), findsOneWidget);
    expect(find.text('Balai Warga'), findsOneWidget);
    verify(() => jadwalCubit.loadJadwal(date: selectedDate)).called(1);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Terbitkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);

    final nextDate = selectedDate.add(const Duration(days: 1));
    final nextDateParam = '${nextDate.year.toString().padLeft(4, '0')}-'
        '${nextDate.month.toString().padLeft(2, '0')}-'
        '${nextDate.day.toString().padLeft(2, '0')}';
    when(() => jadwalCubit.loadJadwal(date: nextDate)).thenAnswer((_) async {});
    _stubCalendarLoad(jadwalCubit, nextDate);
    router.go('${JadwalPage.route}?date=$nextDateParam');
    await tester.pumpAndSettle();

    expect(
      find.text(formatJadwalDayHeading(nextDate, today: today)),
      findsOneWidget,
    );
    verify(() => jadwalCubit.loadJadwal(date: nextDate)).called(1);

    final manualDate = DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day == 15 ? 16 : 15,
    );
    when(() => jadwalCubit.loadJadwal(date: manualDate))
        .thenAnswer((_) async {});
    await tester.tap(find.byKey(const ValueKey('jadwal-calendar-toggle')));
    await tester.pumpAndSettle();
    final manualDateCell = find.byKey(ValueKey(
      'jadwal-date-${manualDate.year}-${manualDate.month}-${manualDate.day}',
    ));
    await tester.ensureVisible(manualDateCell);
    await tester.tap(manualDateCell);
    await tester.pumpAndSettle();
    expect(
      find.text(formatJadwalDayHeading(manualDate, today: today)),
      findsOneWidget,
    );

    authenticationStates.add(
      Authenticated(
        authEntity: const AuthEntity(
          id: 'nasabah-1',
          name: 'Nasabah',
          email: 'nasabah@example.com',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(formatJadwalDayHeading(nextDate, today: today)),
      findsOneWidget,
    );
    verify(() => jadwalCubit.loadJadwal(date: nextDate)).called(1);
  });
}

void _stubCalendarLoad(_MockJadwalCubit cubit, DateTime date) {
  final first = DateTime(date.year, date.month, 1);
  final offset = first.weekday - DateTime.monday;
  final firstVisible = first.subtract(Duration(days: offset));
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
  final weekCount = (offset + daysInMonth + 6) ~/ 7;
  final lastVisible = firstVisible.add(Duration(days: weekCount * 7 - 1));
  when(
    () => cubit.loadCalendarDates(
      startDate: firstVisible,
      endDate: lastVisible,
    ),
  ).thenAnswer((_) async {});
}
