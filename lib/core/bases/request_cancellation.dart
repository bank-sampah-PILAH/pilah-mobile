import 'dart:async';

/// Transport-independent cancellation for application requests.
class RequestCancellation {
  final _signal = Completer<String?>();
  String? _reason;

  bool get isCancelled => _signal.isCompleted;
  String? get reason => _reason;
  Future<String?> get whenCancelled => _signal.future;

  void cancel([String? reason]) {
    if (isCancelled) return;
    _reason = reason;
    _signal.complete(reason);
  }
}
