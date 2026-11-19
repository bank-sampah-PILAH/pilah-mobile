import 'package:flutter/foundation.dart';

/// Whether the shared tile sources are answering (PIL-326 fallback).
///
/// One session-sticky signal for every map in the app. Screens that can work
/// without tiles read this instead of detecting failures themselves, so the
/// degraded UI never disagrees from screen to screen.
class TileHealth extends ChangeNotifier {
  TileHealth({this.ambang = 4});

  /// The instance the tile layer reports to and the degraded screens read.
  static final TileHealth instance = TileHealth();

  /// Failed tiles before the map counts as unusable. Small enough to notice on
  /// the first screenful, large enough that one bad tile is not an outage.
  final int ambang;

  int _galat = 0;
  bool _buruk = false;

  bool get buruk => _buruk;

  /// Reports one tile that failed on every configured source.
  void catatGalat() {
    if (_buruk) return;
    _galat++;
    if (_galat < ambang) return;
    _buruk = true;
    notifyListeners();
  }

  /// Back to healthy: the retry affordance, and the reset the tests need.
  void pulihkan() {
    _galat = 0;
    _buruk = false;
    notifyListeners();
  }
}
