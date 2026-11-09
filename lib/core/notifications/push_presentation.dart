import 'dart:async';

class PushPresentation<T> {
  PushPresentation(
      {required this.foreground,
      required this.opened,
      required this.initialOpen,
      required this.show,
      required this.open});

  final Stream<T> foreground;
  final Stream<void> opened;
  final Future<bool> Function() initialOpen;
  final void Function(T) show;
  final void Function() open;
  StreamSubscription<T>? _foregroundSubscription;
  StreamSubscription<void>? _openedSubscription;
  bool _active = false;

  Future<void> start() async {
    if (_active) return;
    _active = true;
    _foregroundSubscription = foreground.listen(show);
    _openedSubscription = opened.listen((_) => open());
    if (await initialOpen() && _active) open();
  }

  Future<void> stop() async {
    _active = false;
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
  }
}
