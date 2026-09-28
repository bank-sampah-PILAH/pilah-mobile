import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _JadwalRepository extends Mock implements JadwalRepository {}

void main() {
  testWidgets('shows the nearest schedule and opens its date', (tester) async {
    final auth = _Auth();
    final jadwalRepository = _JadwalRepository();
    final today = DateUtils.dateOnly(DateTime.now());
    final ongoingDate = today.subtract(const Duration(days: 1));
    final ongoing = JadwalEntity(
      id: 'ongoing',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'Sedang berlangsung',
      mulaiPada:
          DateTime(ongoingDate.year, ongoingDate.month, ongoingDate.day, 10),
      selesaiPada: today.add(const Duration(days: 1)),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );
    final nearestDate = today.add(const Duration(days: 2));
    final nearest = JadwalEntity(
      id: 'nearest',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'Penimbangan',
      mulaiPada:
          DateTime(nearestDate.year, nearestDate.month, nearestDate.day, 10),
      selesaiPada:
          DateTime(nearestDate.year, nearestDate.month, nearestDate.day, 11),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );
    final laterDate = today.add(const Duration(days: 7));
    final later = JadwalEntity(
      id: 'later',
      bankSampahId: 'bank-1',
      jenisKegiatan: 'Pengumpulan',
      mulaiPada: DateTime(laterDate.year, laterDate.month, laterDate.day, 10),
      selesaiPada: DateTime(laterDate.year, laterDate.month, laterDate.day, 11),
      lokasi: 'Balai Warga',
      status: 'diterbitkan',
    );

    when(() => jadwalRepository.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Right(JadwalPageResult(
        items: [ongoing],
        totalCount: 3,
        hasMore: true,
      )),
    );
    when(() => jadwalRepository.getJadwal(page: 2, date: null)).thenAnswer(
      (_) async => Right(JadwalPageResult(
        items: [nearest, later],
        totalCount: 3,
        hasMore: false,
      )),
    );
    whenListen(
      auth,
      const Stream<AuthenticationStates>.empty(),
      initialState: Authenticated(
        authEntity: AuthEntity(
          id: 'nasabah-1',
          name: 'Siti',
          email: 'siti@example.test',
          photoUrl: '',
          token: 'token',
          role: 'nasabah',
          nextStep: 'nasabah_dashboard',
        ),
      ),
    );

    di.registerSingleton<NasabahRepository>(PreviewNasabahRepository());
    di.registerSingleton<JadwalRepository>(jadwalRepository);
    final router = GoRouter(initialLocation: '/beranda', routes: [
      GoRoute(
        path: '/beranda',
        builder: (_, __) => const BerandaNasabahPage(),
      ),
      GoRoute(
        path: '/jadwal',
        builder: (_, state) => Scaffold(
          body: Text(
              'Tanggal: ${state.uri.queryParameters['date'] ?? 'tidak dipilih'}'),
        ),
      ),
    ]);
    addTearDown(() async {
      router.dispose();
      await auth.close();
      await di.unregister<NasabahRepository>();
      await di.unregister<JadwalRepository>();
    });

    await tester.pumpWidget(
      BlocProvider<AuthenticationBloc>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Penimbangan'), 240);
    expect(find.text('Penimbangan'), findsOneWidget);
    expect(find.text('Pengumpulan'), findsNothing);
    expect(find.text('Balai Warga'), findsOneWidget);
    await tester.tap(find.text('Penimbangan'));
    await tester.pumpAndSettle();

    final expectedDate = '${nearestDate.year.toString().padLeft(4, '0')}-'
        '${nearestDate.month.toString().padLeft(2, '0')}-'
        '${nearestDate.day.toString().padLeft(2, '0')}';
    expect(find.text('Tanggal: $expectedDate'), findsOneWidget);
  });
}
