import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_screen_tracker.dart';

import '../../support/fake_analytics_client.dart';

void main() {
  late FakeAnalyticsClient client;
  late _Notifier routerChanges;
  late String? currentPath;
  late DateTime now;
  late AnalyticsScreenTracker tracker;

  void goTo(String? path) {
    currentPath = path;
    routerChanges.notify();
  }

  setUp(() {
    client = FakeAnalyticsClient();
    routerChanges = _Notifier();
    currentPath = '/dashboard';
    now = DateTime(2026, 11, 3, 9);
    tracker = AnalyticsScreenTracker(
      client: client,
      changes: routerChanges,
      currentPath: () => currentPath,
      clock: () => now,
    )
      ..attach()
      ..reportCurrent();
  });

  tearDown(() => tracker.dispose());

  test(
      'listening alone sends nothing: the first screen goes out only when '
      'asked for, so it can never be sent twice', () {
    final other = FakeAnalyticsClient();
    final fresh = AnalyticsScreenTracker(
      client: other,
      changes: routerChanges,
      currentPath: () => currentPath,
      clock: () => now,
    )..attach();
    addTearDown(fresh.dispose);

    expect(other.screens, isEmpty);

    fresh.reportCurrent();

    expect(other.screens, ['dashboard']);
  });

  test('reports the screen it starts on', () {
    expect(client.screens, ['dashboard']);
  });

  test('reports each new screen', () {
    goTo('/nasabah');
    goTo('/jadwal');

    expect(client.screens, ['dashboard', 'nasabah', 'jadwal']);
  });

  test('names a screen after its route pattern, never the real values', () {
    goTo('/nasabah/:id');

    expect(client.screens.last, 'nasabah/:id');
  });

  test('calls the home screen beranda', () {
    goTo('/');

    expect(client.screens.last, 'beranda');
  });

  test('ignores a change that stays on the same screen', () {
    goTo('/dashboard');
    goTo('/dashboard');

    expect(client.screens, ['dashboard']);
  });

  test('ignores a moment when there is no screen yet', () {
    goTo(null);
    goTo('');

    expect(client.screens, ['dashboard']);
  });

  test('the first screen comes with no previous screen to describe', () {
    expect(client.screenProps, [<String, Object>{}]);
  });

  test('a new screen says which one it follows and for how long', () {
    now = now.add(const Duration(seconds: 12, milliseconds: 400));

    goTo('/nasabah');

    expect(client.screens, ['dashboard', 'nasabah']);
    expect(client.screenProps.last, {
      'layar_sebelumnya': 'dashboard',
      'durasi_layar_sebelumnya_detik': 12,
    });
    // One event per move, not a second one for leaving.
    expect(client.events, isEmpty);
    expect(client.log, ['screen:dashboard', 'screen:nasabah']);
  });

  test('reportCurrent repeats the current screen with nothing before it', () {
    goTo('/riwayat');
    client.log.clear();

    tracker.reportCurrent();

    expect(client.log, ['screen:riwayat']);
    expect(client.screenProps.last, isEmpty);
  });

  test('time on a screen counts from when analytics started hearing of it', () {
    // The user had been on the dashboard for half a minute before they agreed.
    now = now.add(const Duration(seconds: 30));
    tracker.reportCurrent();

    now = now.add(const Duration(seconds: 5));
    goTo('/nasabah');

    expect(client.screenProps.last['durasi_layar_sebelumnya_detik'], 5);
  });

  test('stops listening once disposed', () {
    tracker.dispose();

    goTo('/jadwal');

    expect(client.screens, ['dashboard']);
  });
}

class _Notifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
