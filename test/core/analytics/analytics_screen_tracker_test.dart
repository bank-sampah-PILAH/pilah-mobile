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
    )..attach();
  });

  tearDown(() => tracker.dispose());

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

  test('says how long the screen was open when leaving it', () {
    now = now.add(const Duration(seconds: 12, milliseconds: 400));

    goTo('/nasabah');

    expect(client.events.map((e) => e.name), ['layar_ditinggalkan']);
    expect(client.events.single.properties, {
      'layar': 'dashboard',
      'durasi_detik': 12,
    });
    // The screen left is reported before the new one is.
    expect(client.log, [
      'screen:dashboard',
      'capture:layar_ditinggalkan',
      'screen:nasabah',
    ]);
  });

  test('reportCurrent repeats the current screen without a leave event', () {
    goTo('/riwayat');
    client.log.clear();

    tracker.reportCurrent();

    expect(client.log, ['screen:riwayat']);
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
