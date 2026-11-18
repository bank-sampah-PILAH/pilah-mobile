import 'dart:async';

class PushSession {
  PushSession(
      {required this.getToken,
      required this.register,
      required this.remove,
      required this.tokenRefresh,
      this.invalidate,
      Future<void> Function(Duration)? retryDelay})
      : retryDelay = retryDelay ?? Future<void>.delayed;

  final Future<String?> Function() getToken;
  final Future<void> Function(String) register;
  final Future<void> Function(String) remove;
  final Stream<String> tokenRefresh;
  final Future<void> Function()? invalidate;
  final Future<void> Function(Duration) retryDelay;
  bool _enabled = false;
  StreamSubscription<String>? _subscription;
  String? _token;
  Future<void> _pending = Future.value();

  Future<void> start() {
    _enabled = true;
    final operation = _pending.catchError((_) {}).then((_) => _start());
    _pending = operation;
    return operation;
  }

  Future<void> _start() async {
    await _subscription?.cancel();
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      await _register(token);
      if (_enabled) _token = token;
    }
    if (!_enabled) return;
    _subscription = tokenRefresh.listen(_handleTokenRefresh);
  }

  void _handleTokenRefresh(String token) {
    if (!_enabled) return;
    _pending = _pending.catchError((_) {}).then((_) async {
      if (!_enabled) return;
      await _register(token);
      if (!_enabled) return;
      final previous = _token;
      _token = token;
      if (previous != null && previous != token) await remove(previous);
    }).catchError((_) {});
  }

  Future<void> _register(String token) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (!_enabled) return;
      try {
        await register(token);
        return;
      } catch (_) {
        if (attempt == 2) rethrow;
        await retryDelay(Duration(seconds: 2 << attempt));
      }
    }
  }

  Future<void> stop() {
    _enabled = false;
    final operation = _pending.catchError((_) {}).then((_) async {
      await _subscription?.cancel();
      _subscription = null;
      try {
        final token = _token ?? await getToken();
        _token = null;
        if (token != null && token.isNotEmpty) await remove(token);
      } finally {
        await invalidate?.call();
      }
    });
    _pending = operation;
    return operation;
  }
}
