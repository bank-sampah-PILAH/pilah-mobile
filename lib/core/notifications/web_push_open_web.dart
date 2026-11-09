import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

final _opens = StreamController<void>.broadcast();
final _listener = ((web.Event event) {
  if (_opens.hasListener && takeWebPushOpen()) _opens.add(null);
}).toJS;

Stream<void> get webPushOpens {
  web.window.removeEventListener('pilah-notification-open', _listener);
  web.window.addEventListener('pilah-notification-open', _listener);
  return _opens.stream;
}

bool takeWebPushOpen() {
  final pending =
      web.window.sessionStorage.getItem('pilah-notification-open') == '1';
  if (pending) web.window.sessionStorage.removeItem('pilah-notification-open');
  return pending;
}
