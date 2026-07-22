import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Holds the invite token captured from an `/invite?token=…` deep link until the
/// user has signed in and reached the join screen.
///
/// Deliberately in-memory only. The token grants membership of a bank sampah,
/// and the link that carries it can always be tapped again, so losing it on
/// app restart is preferable to persisting a credential to disk.
///
/// It is a [ChangeNotifier] because a link can arrive while the screen that
/// cares about it is already on top. The router cannot help there: a redirect
/// that resolves back to the location already showing produces an equal
/// `RouteMatchList`, and `GoRouterDelegate.setNewRoutePath` returns early
/// without notifying — no rebuild, no re-run of the route builder. Screens whose
/// UI depends on invite mode listen here instead.
@lazySingleton
class InviteTokenStore extends ChangeNotifier {
  String? _token;

  String? get token => _token;

  bool get hasToken => _token?.isNotEmpty ?? false;

  /// Stores [token], ignoring blank values so a malformed link can't put the
  /// app into invite mode with nothing to submit.
  void save(String token) {
    final value = token.trim();
    if (value.isEmpty) return;
    if (value == _token) return;
    _token = value;
    notifyListeners();
  }

  void clear() {
    if (_token == null) return;
    _token = null;
    notifyListeners();
  }
}
