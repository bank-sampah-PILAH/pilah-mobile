import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';

/// Reports which screen the user is on, and how long the one before it stayed
/// open.
///
/// A screen is named after its route pattern (`nasabah/:id`), not the address
/// the user is on, so an id or any other value in the address never reaches
/// analytics. Whether anything is actually sent is up to the client: it ignores
/// everything until the user has agreed.
class AnalyticsScreenTracker {
  AnalyticsScreenTracker({
    required this.client,
    required this.changes,
    required this.currentPath,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final AnalyticsClient client;

  /// Notifies whenever the user may have moved to another screen.
  final Listenable changes;

  /// The route pattern of the screen showing now, such as `/nasabah/:id`, or
  /// null when there is none yet.
  final String? Function() currentPath;

  final DateTime Function() _clock;

  String? _screen;
  DateTime? _since;

  /// Starts listening, and reports the screen showing now.
  void attach() {
    changes.addListener(_onChange);
    _onChange();
  }

  void dispose() => changes.removeListener(_onChange);

  /// Reports the screen showing now again, for when analytics has just been
  /// switched on and has not heard about it yet.
  void reportCurrent() {
    final screen = _screen;
    if (screen == null) return;
    client.screen(screen);
    // What came before is nothing analytics was told about, so time on this
    // screen counts from now.
    _since = _clock();
  }

  void _onChange() {
    final screen = _nameFor(currentPath());
    if (screen == null || screen == _screen) return;

    final previous = _screen;
    final since = _since;
    final now = _clock();
    client.screen(screen, {
      // One event per move: it says where the user came from and how long they
      // stayed there.
      if (previous != null && since != null) ...{
        'layar_sebelumnya': previous,
        'durasi_layar_sebelumnya_detik': now.difference(since).inSeconds,
      },
    });
    _screen = screen;
    _since = now;
  }

  static String? _nameFor(String? path) {
    if (path == null || path.isEmpty) return null;
    final name = path.replaceFirst(RegExp(r'^/'), '');
    return name.isEmpty ? 'beranda' : name;
  }
}
