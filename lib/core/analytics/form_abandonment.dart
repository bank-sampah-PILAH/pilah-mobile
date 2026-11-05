/// Tells a form that was left without being saved from one that was saved, so
/// each is reported once and never both.
///
/// A save outlives the form that started it: the pengurus can close the panel
/// while the request is still running. Closing then is not yet leaving without
/// saving, so the verdict waits for how the request ends. A save that lands is
/// a save. One that fails makes the closed form a cancelled one.
class FormAbandonment {
  FormAbandonment(this._report);

  final void Function() _report;

  bool _open = false;
  bool _saved = false;
  bool _sending = false;
  bool _closed = false;
  bool _reported = false;

  /// The form was opened.
  void opened() {
    _open = true;
    _saved = false;
    _sending = false;
    _closed = false;
    _reported = false;
  }

  /// The request to save was sent.
  void sending() => _sending = true;

  /// The request failed or was refused.
  void sendFailed() {
    _sending = false;
    if (_closed) _reportOnce();
  }

  /// The form was saved.
  void saved() {
    _saved = true;
    _sending = false;
  }

  /// The form was closed.
  void closed() {
    if (!_open || _closed) return;
    _closed = true;
    if (!_sending) _reportOnce();
  }

  void _reportOnce() {
    if (!_open || _saved || _reported) return;
    _reported = true;
    _report();
  }
}
