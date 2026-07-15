import 'package:injectable/injectable.dart';

/// Holds the invite token captured from an `/invite?token=…` deep link until the
/// user has signed in and reached the join screen.
///
/// Deliberately in-memory only. The token grants membership of a bank sampah,
/// and the link that carries it can always be tapped again, so losing it on
/// app restart is preferable to persisting a credential to disk.
@lazySingleton
class InviteTokenStore {
  String? _token;

  String? get token => _token;

  bool get hasToken => _token?.isNotEmpty ?? false;

  /// Stores [token], ignoring blank values so a malformed link can't put the
  /// app into invite mode with nothing to submit.
  void save(String token) {
    final value = token.trim();
    if (value.isEmpty) return;
    _token = value;
  }

  void clear() => _token = null;
}
