import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_events.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/pages/beranda_nasabah_page.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/preview/preview_nasabah_repository.dart';
import 'package:pilah_mobile/services/di.dart';

class _Auth extends MockBloc<AuthenticationEvent, AuthenticationStates>
    implements AuthenticationBloc {}

class _JadwalRepository extends Mock implements JadwalRepository {}

/// A preview repository whose home carries the given balance and activities.
class _HomeRepository extends PreviewNasabahRepository {
  _HomeRepository(this.balanceUpdatedAt, this.activities,
      {this.requireSelection = false,
      this.invalidMembershipId,
      this.invalidMembershipStatusCode});

  final DateTime? balanceUpdatedAt;
  final List<NasabahActivity> activities;
  final bool requireSelection;
  final String? invalidMembershipId;
  final int? invalidMembershipStatusCode;
  final asked = <String?>[];

  @override
  Future<NasabahHome> home({String? membershipId}) async {
    asked.add(membershipId);
    if (membershipId == invalidMembershipId &&
        invalidMembershipStatusCode != null) {
      throw NasabahApiException('Saved membership is no longer eligible.',
          statusCode: invalidMembershipStatusCode);
    }
    if (requireSelection && membershipId == null) {
      throw const NasabahApiException('Pilih bank sampah Anda.', choices: [
        MembershipChoice('membership-2', 'Bank Sampah Lestari'),
      ]);
    }
    return NasabahHome(
      await profile(),
      membershipId ?? 'membership-1',
      await bank(''),
      NasabahBalance('12500.50', balanceUpdatedAt),
      activities,
    );
  }
}

class _MemoryStorage implements AppStorage {
  final values = <String, Object>{};
  bool failReads = false;

  @override
  Future<void> init() async {}
  @override
  Future<void> put(String key, dynamic value) async => values[key] = value;
  @override
  Future<T?> get<T>(String key) async {
    if (failReads) throw StateError('storage unavailable');
    return values[key] as T?;
  }

  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> clear() async => values.clear();
  @override
  Future<bool> contains(String key) async => values.containsKey(key);
}

class _DelayedReadStorage extends _MemoryStorage {
  final savedSelection = Completer<Object?>();

  @override
  Future<T?> get<T>(String key) async {
    if (key == 'active_membership_id:nasabah-1') {
      return (await savedSelection.future) as T?;
    }
    return super.get<T>(key);
  }
}

void _registerStorage(AppStorage storage) {
  const name = 'shared_preferences';
  final previous = di.isRegistered<AppStorage>(instanceName: name)
      ? di<AppStorage>(instanceName: name)
      : null;
  if (previous != null) di.unregister<AppStorage>(instanceName: name);
  di.registerSingleton<AppStorage>(storage, instanceName: name);
  addTearDown(() async {
    if (di.isRegistered<AppStorage>(instanceName: name)) {
      await di.unregister<AppStorage>(instanceName: name);
    }
    if (previous != null) {
      di.registerSingleton<AppStorage>(previous, instanceName: name);
    }
  });
}

void main() {
  late _Auth auth;
  late _JadwalRepository jadwal;

  setUp(() {
    auth = _Auth();
    jadwal = _JadwalRepository();
    when(() =>
            jadwal.getJadwal(page: 1, date: null, membershipId: 'membership-1'))
        .thenAnswer(
      (_) async => const Right(
          JadwalPageResult(items: [], totalCount: 0, hasMore: false)),
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
    di.registerSingleton<JadwalRepository>(jadwal);
  });

  tearDown(() async {
    if (di.isRegistered<NasabahRepository>()) {
      await di.unregister<NasabahRepository>();
    }
    await di.unregister<JadwalRepository>();
    await auth.close();
  });

  Future<void> pumpHome(
      WidgetTester tester, NasabahRepository repository) async {
    di.registerSingleton<NasabahRepository>(repository);
    final router = GoRouter(initialLocation: '/beranda', routes: [
      GoRoute(path: '/beranda', builder: (_, __) => const BerandaNasabahPage()),
      GoRoute(
        path: '/jadwal',
        builder: (_, state) => const Scaffold(body: Text('halaman jadwal')),
      ),
      GoRoute(
        path: ApprovalBankSampahListPage.route,
        builder: (_, __) => const Scaffold(body: Text('approval list')),
      ),
      GoRoute(
        path: AppLocations.history,
        builder: (_, state) => Scaffold(
            body:
                Text('riwayat ${state.uri.queryParameters['keanggotaan_id']}')),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(BlocProvider<AuthenticationBloc>.value(
      value: auth,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  // The greeting follows the clock, so each time of day is checked against a
  // fixed one and the result does not depend on when the suite runs.
  const greetings = {
    5: 'Selamat pagi',
    12: 'Selamat siang',
    16: 'Selamat sore',
    20: 'Selamat malam',
  };
  for (final entry in greetings.entries) {
    testWidgets('greets ${entry.value.toLowerCase()} at ${entry.key}:00',
        (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 10, 6, entry.key)), () async {
        await pumpHome(tester, _HomeRepository(null, const []));

        expect(find.text(entry.value), findsOneWidget);
      });
    });
  }

  testWidgets('restores and persists the saved bank selection', (tester) async {
    const userId = 'nasabah-1';
    final storage = _MemoryStorage()
      ..values['active_membership_id:$userId'] = 'membership-2';
    _registerStorage(storage);
    final repository = _HomeRepository(null, const [], requireSelection: true);

    await pumpHome(tester, repository);

    expect(repository.asked.last, 'membership-2');
    expect(storage.values['active_membership_id:$userId'], 'membership-2');
    expect(find.text('Rp 12.500,50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unreadable saved selection falls back to membership choices',
      (tester) async {
    final storage = _MemoryStorage()..failReads = true;
    _registerStorage(storage);
    final repository = _HomeRepository(null, const [], requireSelection: true);

    await pumpHome(tester, repository);

    expect(repository.asked.last, isNull);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new selection wins over a delayed saved-selection read',
      (tester) async {
    final storage = _DelayedReadStorage()
      ..values['active_membership_id:nasabah-1'] = 'membership-1';
    _registerStorage(storage);
    final repository = _HomeRepository(null, const [], requireSelection: true);

    await pumpHome(tester, repository);
    await tester.tap(find.text('Bank Sampah Lestari'));
    await tester.pumpAndSettle();
    expect(repository.asked.last, 'membership-2');

    storage.savedSelection.complete('membership-1');
    await tester.pumpAndSettle();

    expect(repository.asked.last, 'membership-2');
    expect(repository.asked, isNot(contains('membership-1')));
    expect(storage.values['active_membership_id:nasabah-1'], 'membership-2');
  });

  testWidgets(
      'home reloads the stored selection after returning from approvals',
      (tester) async {
    const key = 'active_membership_id:nasabah-1';
    final storage = _MemoryStorage()..values[key] = 'membership-1';
    _registerStorage(storage);
    final repository = _HomeRepository(null, const []);

    await pumpHome(tester, repository);
    expect(repository.asked.last, 'membership-1');
    await tester.tap(find.text('Lihat Status Approval Bank Sampah'));
    await tester.pumpAndSettle();
    expect(find.text('approval list'), findsOneWidget);

    storage.values[key] = 'membership-2';
    GoRouter.of(tester.element(find.text('approval list'))).pop();
    await tester.pumpAndSettle();

    expect(repository.asked.last, 'membership-2');
  });

  testWidgets('clears an invalid saved membership and offers another bank',
      (tester) async {
    const key = 'active_membership_id:nasabah-1';
    final storage = _MemoryStorage()..values[key] = 'membership-stale';
    _registerStorage(storage);
    final repository = _HomeRepository(null, const [],
        requireSelection: true,
        invalidMembershipId: 'membership-stale',
        invalidMembershipStatusCode: 404);

    await pumpHome(tester, repository);

    expect(repository.asked, contains('membership-stale'));
    expect(repository.asked.last, isNull);
    expect(storage.values.containsKey(key), isFalse);
    expect(find.text('Bank Sampah Lestari'), findsOneWidget);
  });

  testWidgets('the balance card names the latest activity and its date',
      (tester) async {
    await pumpHome(
        tester,
        _HomeRepository(null, [
          NasabahActivity(
              'a1', DateTime(2026, 9, 23, 9), 'pencairan', '5000.00'),
        ]));

    expect(find.text('Pencairan · 23/09/2026'), findsOneWidget);
  });

  testWidgets('an unrecognised activity type is shown as sent', (tester) async {
    await pumpHome(
        tester,
        _HomeRepository(null, [
          NasabahActivity('a1', DateTime(2026, 9, 23, 9), 'koreksi', '1000.00'),
        ]));

    expect(find.text('koreksi · 23/09/2026'), findsOneWidget);
  });

  testWidgets('without activity it says when the balance was updated',
      (tester) async {
    await pumpHome(tester, _HomeRepository(DateTime(2026, 9, 20, 9), const []));

    expect(find.text('Diperbarui 20/09/2026'), findsOneWidget);
  });

  testWidgets('Semua links go to the schedule and to the history',
      (tester) async {
    await pumpHome(tester, _HomeRepository(null, const []));

    await tester.tap(find.widgetWithText(TextButton, 'Semua').first);
    await tester.pumpAndSettle();
    expect(find.text('halaman jadwal'), findsOneWidget);

    // Back to the home page for the second link.
    final router = GoRouter.of(tester.element(find.text('halaman jadwal')));
    router.go('/beranda');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Semua').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Semua').last);
    await tester.pumpAndSettle();
    expect(find.text('riwayat membership-1'), findsOneWidget);
  });

  testWidgets('choosing the bank again reloads the home without a membership',
      (tester) async {
    final repository = _HomeRepository(null, const []);
    await pumpHome(tester, repository);
    expect(repository.asked, [null]);

    await tester.tap(find.byTooltip('Pilih ulang bank sampah'));
    await tester.pumpAndSettle();

    expect(repository.asked, [null, null]);
  });

  testWidgets('a failing schedule request is reported in its own card',
      (tester) async {
    when(() =>
            jadwal.getJadwal(page: 1, date: null, membershipId: 'membership-1'))
        .thenAnswer(
      (_) async => Left(GeneralException(message: 'offline')),
    );
    await pumpHome(tester, _HomeRepository(null, const []));

    expect(find.text('offline'), findsOneWidget);
  });

  testWidgets('every activity type keeps its title in the shared list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NasabahActivityList(activities: [
          NasabahActivity('a', DateTime(2026, 9, 1), 'setoran', '1000.00'),
          NasabahActivity('b', DateTime(2026, 9, 2), 'pencairan', '500.00'),
          NasabahActivity('c', DateTime(2026, 9, 3), 'koreksi', '100.00'),
        ]),
      ),
    ));

    expect(find.text('Setoran'), findsOneWidget);
    expect(find.text('Pencairan'), findsOneWidget);
    expect(find.text('koreksi'), findsOneWidget);
  });
}
