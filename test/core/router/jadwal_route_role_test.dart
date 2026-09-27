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
import 'package:pilah_mobile/services/di.dart';

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
    final authenticationBloc = _MockAuthenticationBloc();
    final authenticationStates = StreamController<AuthenticationStates>();
    addTearDown(authenticationStates.close);
    final jadwalCubit = _MockJadwalCubit();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startsAt = DateTime(today.year, today.month, today.day, 9).toUtc();
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
    _stubCalendarLoad(jadwalCubit, today);

    final router = AppRouterConfig.getRouter();
    router.go(JadwalPage.route);
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

      expect(find.text('Jadwal Bank Sampah'), findsOneWidget);
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

    expect(find.text('Jadwal Bank Sampah'), findsOneWidget);
    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Terbitkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);
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
