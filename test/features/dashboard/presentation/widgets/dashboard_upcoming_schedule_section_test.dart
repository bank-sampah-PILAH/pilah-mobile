import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/features/dashboard/presentation/widgets/dashboard_upcoming_schedule_section.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';

class _JadwalRepository extends Mock implements JadwalRepository {}

final _testNow = DateTime(2026, 6, 1, 9);

void main() {
  testWidgets('shows loading then the empty schedule state', (tester) async {
    final repository = _JadwalRepository();
    final response = Completer<Either<NetworkException, JadwalPageResult>>();
    when(() => repository.getJadwal(page: 1, date: null))
        .thenAnswer((_) => response.future);

    await _pumpSection(tester, repository);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(Right(_page(const [])));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada jadwal mendatang.'), findsOneWidget);
  });

  testWidgets('paginates and lists ongoing then future published events',
      (tester) async {
    final repository = _JadwalRepository();
    final past = _schedule(
      id: 'past',
      title: 'Jadwal Lampau',
      start: DateTime(2026, 5, 31, 10),
    );
    final ongoing = _schedule(
      id: 'ongoing',
      title: 'Sedang berlangsung',
      start: DateTime(2026, 6, 1, 8, 30),
    );
    final draft = _schedule(
      id: 'draft',
      title: 'Jadwal Draft',
      start: DateTime(2026, 6, 2, 9),
      status: 'draft',
    );
    final far = _schedule(
      id: 'far',
      title: 'Jadwal Jauh',
      start: DateTime(2026, 6, 10, 10),
    );
    final nearest = _schedule(
      id: 'nearest',
      title: 'Penimbangan',
      start: DateTime(2026, 6, 2, 10),
    );
    final later = _schedule(
      id: 'later',
      title: 'Pengumpulan',
      start: DateTime(2026, 6, 5, 10),
    );
    final farthest = _schedule(
      id: 'farthest',
      title: 'Jadwal Terjauh',
      start: DateTime(2026, 6, 20, 10),
    );
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer(
      (_) async => Right(_page([past, ongoing, draft, far], hasMore: true)),
    );
    when(() => repository.getJadwal(page: 2, date: null)).thenAnswer(
      (_) async => Right(_page([later, nearest, farthest])),
    );

    await _pumpSection(tester, repository);
    await tester.pumpAndSettle();

    // Ongoing schedules appear before the three nearest future events.
    expect(find.text('Sedang berlangsung'), findsOneWidget);
    expect(find.text('Penimbangan'), findsOneWidget);
    expect(find.text('Balai Warga'), findsNWidgets(3));
    expect(find.text('Pengumpulan'), findsOneWidget);
    expect(find.text('Jadwal Jauh'), findsNothing);
    expect(tester.getTopLeft(find.text('Sedang berlangsung')).dy,
        lessThan(tester.getTopLeft(find.text('Penimbangan')).dy));
    expect(tester.getTopLeft(find.text('Penimbangan')).dy,
        lessThan(tester.getTopLeft(find.text('Pengumpulan')).dy));
    expect(find.text('Jadwal Terjauh'), findsNothing, reason: 'only three');
    expect(find.text('Jadwal Lampau'), findsNothing);
    expect(find.text('Jadwal Draft'), findsNothing);
    verify(() => repository.getJadwal(page: 1, date: null)).called(1);
    verify(() => repository.getJadwal(page: 2, date: null)).called(1);

    await tester.tap(find.text('Penimbangan'));
    await tester.pumpAndSettle();
    expect(find.text('Tanggal: 2026-06-02'), findsOneWidget);
  });

  testWidgets('opens the complete schedule list from the section header',
      (tester) async {
    final repository = _JadwalRepository();
    when(() => repository.getJadwal(page: 1, date: null))
        .thenAnswer((_) async => Right(_page(const [])));

    await _pumpSection(tester, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat Semua'));
    await tester.pumpAndSettle();

    expect(find.text('Tanggal: none'), findsOneWidget);
  });

  testWidgets('shows an error and retries without affecting the empty state',
      (tester) async {
    final repository = _JadwalRepository();
    var attempts = 0;
    final upcoming = _schedule(
      id: 'upcoming',
      title: 'Penimbangan',
      start: DateTime(2026, 6, 2, 10),
    );
    when(() => repository.getJadwal(page: 1, date: null)).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) return Left(GeneralException(message: 'offline'));
      return Right(_page([upcoming]));
    });

    await _pumpSection(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat jadwal mendatang.'), findsOneWidget);
    expect(find.text('Belum ada jadwal mendatang.'), findsNothing);

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Penimbangan'), findsOneWidget);
    expect(attempts, 2);
  });
}

Future<void> _pumpSection(
  WidgetTester tester,
  JadwalRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => Scaffold(
          body: SingleChildScrollView(
            child: DashboardUpcomingScheduleSection(
              repository: repository,
              now: () => _testNow,
            ),
          ),
        ),
      ),
      GoRoute(
        path: JadwalPage.route,
        builder: (context, state) => Scaffold(
          body: Text('Tanggal: ${state.uri.queryParameters['date'] ?? 'none'}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
}

JadwalPageResult _page(List<JadwalEntity> items, {bool hasMore = false}) =>
    JadwalPageResult(
      items: items,
      totalCount: items.length,
      hasMore: hasMore,
    );

JadwalEntity _schedule({
  required String id,
  required String title,
  required DateTime start,
  String status = 'diterbitkan',
}) =>
    JadwalEntity(
      id: id,
      bankSampahId: 'bank-1',
      jenisKegiatan: title,
      mulaiPada: start,
      selesaiPada: start.add(const Duration(hours: 1)),
      lokasi: 'Balai Warga',
      status: status,
    );
