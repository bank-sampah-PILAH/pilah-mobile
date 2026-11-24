import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_props.dart';
import 'package:pilah_mobile/core/analytics/analytics_screen_tracker.dart';
import 'package:pilah_mobile/core/errors/error_flows.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';

class _RecordingReporter implements ErrorReporter {
  final contexts = <Map<String, Object?>>[];

  @override
  void report(
    Object error,
    StackTrace stack, {
    Map<String, Object?> context = const {},
    bool handled = true,
  }) =>
      contexts.add(context);
}

void main() {
  group('AnalyticsScreenTracker.nameFor', () {
    test('names a screen after its route pattern, without the slash', () {
      expect(AnalyticsScreenTracker.nameFor('/nasabah/:id'), 'nasabah/:id');
      expect(AnalyticsScreenTracker.nameFor('/'), 'beranda');
      expect(AnalyticsScreenTracker.nameFor(null), isNull);
    });
  });

  group('ErrorFlows.nameFor', () {
    test('names the core flows', () {
      expect(ErrorFlows.nameFor('transaksi-baru'), 'setoran');
      expect(ErrorFlows.nameFor('riwayat'), 'riwayat');
      expect(ErrorFlows.nameFor('riwayat/:id'), 'riwayat');
      for (final screen in ['login', 'forgot_password', 'choose-role']) {
        expect(ErrorFlows.nameFor(screen), 'login', reason: screen);
      }
    });

    test('gives no flow to any other screen, even one that starts the same',
        () {
      expect(ErrorFlows.nameFor('nasabah'), isNull);
      expect(ErrorFlows.nameFor('riwayat-perubahan-pencairan'), isNull);
    });
  });

  group('ContextualErrorReporter', () {
    test('adds the screen and the flow the error happened in', () {
      final inner = _RecordingReporter();
      final reporter = ContextualErrorReporter(
        inner: inner,
        currentScreen: () => 'transaksi-baru',
      );

      reporter.report(StateError('x'), StackTrace.current);

      expect(inner.contexts.single,
          {'layar': 'transaksi-baru', 'alur': 'setoran'});
      // Both names pass the property list, so they are not left out on the way.
      expect(AnalyticsProps.sanitize(inner.contexts.single), isNotEmpty);
      expect(AnalyticsProps.sanitize(inner.contexts.single)['alur'], 'setoran');
    });

    test('adds only the screen where it belongs to no core flow', () {
      final inner = _RecordingReporter();
      final reporter =
          ContextualErrorReporter(inner: inner, currentScreen: () => 'nasabah');

      reporter.report(StateError('x'), StackTrace.current);

      expect(inner.contexts.single, {'layar': 'nasabah'});
    });

    test(
        'adds nothing before there is a screen, and keeps what the caller gave',
        () {
      final inner = _RecordingReporter();
      var screen = null as String?;
      final reporter =
          ContextualErrorReporter(inner: inner, currentScreen: () => screen);

      reporter.report(StateError('x'), StackTrace.current);
      screen = 'nasabah';
      reporter.report(
        StateError('x'),
        StackTrace.current,
        context: {'layar': 'dari_pemanggil'},
      );

      expect(inner.contexts[0], isEmpty);
      expect(inner.contexts[1], {'layar': 'dari_pemanggil'});
    });
  });
}
