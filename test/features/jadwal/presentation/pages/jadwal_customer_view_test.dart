import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _MockJadwalCubit extends MockCubit<JadwalState> implements JadwalCubit {
  final membershipIds = <String?>[];

  @override
  void setMembershipId(String? membershipId) => membershipIds.add(membershipId);
}

class _MemoryStorage implements AppStorage {
  final values = <String, Object>{};

  @override
  Future<void> init() async {}
  @override
  Future<void> put(String key, dynamic value) async => values[key] = value;
  @override
  Future<T?> get<T>(String key) async => values[key] as T?;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> clear() async => values.clear();
  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

class _SessionRepository extends PreviewNasabahRepository {
  _SessionRepository({this.requireChoice = false});

  final bool requireChoice;
  final membershipIds = <String?>[];

  @override
  Future<NasabahHome> home({String? membershipId}) async {
    membershipIds.add(membershipId);
    if (requireChoice && membershipId == null) {
      throw const NasabahApiException('Pilih bank sampah Anda.', choices: [
        MembershipChoice('member-b', 'Bank B'),
      ]);
    }
    return super.home(membershipId: membershipId);
  }
}

void _registerSessionDependencies(
  NasabahRepository repository,
  AppStorage storage,
) {
  const storageName = 'shared_preferences';
  final previousRepository =
      di.isRegistered<NasabahRepository>() ? di<NasabahRepository>() : null;
  final previousStorage = di.isRegistered<AppStorage>(instanceName: storageName)
      ? di<AppStorage>(instanceName: storageName)
      : null;
  if (previousRepository != null) di.unregister<NasabahRepository>();
  if (previousStorage != null) {
    di.unregister<AppStorage>(instanceName: storageName);
  }
  di.registerSingleton<NasabahRepository>(repository);
  di.registerSingleton<AppStorage>(storage, instanceName: storageName);
  addTearDown(() async {
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
    if (di.isRegistered<AppStorage>(instanceName: storageName)) {
      await di.unregister<AppStorage>(instanceName: storageName);
    }
    if (previousRepository != null) {
      di.registerSingleton<NasabahRepository>(previousRepository);
    }
    if (previousStorage != null) {
      di.registerSingleton<AppStorage>(previousStorage,
          instanceName: storageName);
    }
  });
}

void main() {
  testWidgets('restores a saved membership for schedule requests',
      (tester) async {
    const userId = 'saved-user';
    final today = DateUtils.dateOnly(DateTime.now());
    final storage = _MemoryStorage()
      ..values['active_membership_id:$userId'] = 'member-b';
    final repository = _SessionRepository();
    _registerSessionDependencies(repository, storage);
    final cubit = _MockJadwalCubit();
    when(() => cubit.state).thenReturn(JadwalLoaded(const []));
    when(() => cubit.loadJadwal(date: today)).thenAnswer((_) async {});
    _stubCalendarLoad(cubit, today);

    await tester.pumpWidget(BlocProvider<JadwalCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: NasabahJadwalSession(userId: userId, initialDate: today),
      ),
    ));
    await tester.pumpAndSettle();

    expect(repository.membershipIds, contains('member-b'));
    expect(cubit.membershipIds, contains('member-b'));
    expect(storage.values['active_membership_id:$userId'], 'member-b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('persists a membership selected from the schedule page',
      (tester) async {
    const userId = 'choice-user';
    final today = DateUtils.dateOnly(DateTime.now());
    final storage = _MemoryStorage();
    final repository = _SessionRepository(requireChoice: true);
    _registerSessionDependencies(repository, storage);
    final cubit = _MockJadwalCubit();
    when(() => cubit.state).thenReturn(JadwalLoaded(const []));
    when(() => cubit.loadJadwal(date: today)).thenAnswer((_) async {});
    _stubCalendarLoad(cubit, today);

    await tester.pumpWidget(BlocProvider<JadwalCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: NasabahJadwalSession(userId: userId, initialDate: today),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Bank B'), findsOneWidget);

    await tester.tap(find.text('Bank B'));
    await tester.pumpAndSettle();

    expect(repository.membershipIds, [null, 'member-b']);
    expect(cubit.membershipIds, contains('member-b'));
    expect(storage.values['active_membership_id:$userId'], 'member-b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer sees only published schedules in a read-only view', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final cubit = _MockJadwalCubit();
    final schedules = [
      _schedule(
        id: 'published',
        location: 'Balai Warga',
        status: 'diterbitkan',
        isOverlapping: true,
      ),
      _schedule(id: 'draft', location: 'Draf', status: 'draft'),
      _schedule(id: 'cancelled', location: 'Dibatalkan', status: 'dibatalkan'),
      _schedule(id: 'completed', location: 'Selesai', status: 'selesai'),
    ];
    when(() => cubit.state).thenReturn(
      JadwalLoaded(schedules, scheduledDates: {today}, totalCount: 1),
    );
    when(() => cubit.loadJadwal(date: today)).thenAnswer((_) async {});
    _stubCalendarLoad(cubit, today);

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage(customerMode: true)),
      ),
    );
    await tester.pump();

    expect(find.text('Balai Warga'), findsOneWidget);
    expect(find.text('Penimbangan Sampah'), findsOneWidget);
    expect(find.byType(JadwalCalendar), findsOneWidget);
    expect(find.text(formatJadwalDayHeading(today)), findsOneWidget);
    expect(find.text('Draf'), findsNothing);
    expect(find.text('Dibatalkan'), findsNothing);
    expect(find.text('Selesai'), findsNothing);
    expect(find.textContaining('Diterbitkan'), findsOneWidget);
    expect(find.textContaining('diterbitkan'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Batalkan'), findsNothing);
    expect(find.text('Tandai Selesai'), findsNothing);
    expect(find.text('Buat Jadwal'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            widget.message == 'Jadwal bertumpuk di lokasi yang sama',
      ),
      findsNothing,
    );

    await tester.tap(find.text('Balai Warga'));
    await tester.pump();
    expect(find.text('Ubah Jadwal'), findsNothing);
  });

  testWidgets('customer can select a date and sees a read-only empty state', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = today.add(
      Duration(days: today.weekday == DateTime.sunday ? -1 : 1),
    );
    final cubit = _MockJadwalCubit();
    when(() => cubit.state).thenReturn(
      JadwalLoaded(
        [
          _schedule(
            id: 'published',
            location: 'Balai Warga',
            status: 'diterbitkan',
          ),
        ],
        scheduledDates: {today},
        totalCount: 1,
      ),
    );
    when(() => cubit.loadJadwal(date: today)).thenAnswer((_) async {});
    when(() => cubit.loadJadwal(date: selectedDate)).thenAnswer((_) async {});
    _stubCalendarLoad(cubit, today);
    if (selectedDate.month != today.month || selectedDate.year != today.year) {
      _stubCalendarLoad(cubit, selectedDate);
    }

    await tester.pumpWidget(
      BlocProvider<JadwalCubit>.value(
        value: cubit,
        child: const MaterialApp(home: JadwalPage(customerMode: true)),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(
        ValueKey(
          'jadwal-date-${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
        ),
      ),
    );
    await tester.pump();

    verify(() => cubit.loadJadwal(date: selectedDate)).called(1);
    expect(find.text(formatJadwalDayHeading(selectedDate)), findsOneWidget);
    expect(find.text('Belum ada jadwal kegiatan'), findsOneWidget);
    expect(find.text('Buat Jadwal'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}

JadwalEntity _schedule({
  required String id,
  required String location,
  required String status,
  bool isOverlapping = false,
}) {
  final start = _todayAt(9).toUtc();
  return JadwalEntity(
    id: id,
    bankSampahId: 'bank-1',
    jenisKegiatan: 'penimbangan',
    mulaiPada: start,
    selesaiPada: start.add(const Duration(hours: 2)),
    lokasi: location,
    status: status,
    isOverlapping: isOverlapping,
  );
}

DateTime _todayAt(int hour) {
  final today = DateUtils.dateOnly(DateTime.now());
  return DateTime(today.year, today.month, today.day, hour);
}

void _stubCalendarLoad(_MockJadwalCubit cubit, DateTime date) {
  final first = DateTime(date.year, date.month, 1);
  final offset = first.weekday - DateTime.monday;
  final firstVisible = first.subtract(Duration(days: offset));
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
  final weekCount = (offset + daysInMonth + 6) ~/ 7;
  final lastVisible = firstVisible.add(Duration(days: weekCount * 7 - 1));
  when(
    () =>
        cubit.loadCalendarDates(startDate: firstVisible, endDate: lastVisible),
  ).thenAnswer((_) async {});
}
