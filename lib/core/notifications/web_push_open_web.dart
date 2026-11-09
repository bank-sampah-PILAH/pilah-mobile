import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

const _notificationOpenKey = 'pilah-notification-open';

final _opens = StreamController<void>.broadcast();
final _listener = ((web.Event event) {
  if (_opens.hasListener && takeWebPushOpen()) _opens.add(null);
}).toJS;

Stream<void> get webPushOpens {
  web.window.removeEventListener(_notificationOpenKey, _listener);
  web.window.addEventListener(_notificationOpenKey, _listener);
  return _opens.stream;
}

bool takeWebPushOpen() {
  final pending =
      web.window.sessionStorage.getItem(_notificationOpenKey) == '1';
  if (pending) web.window.sessionStorage.removeItem(_notificationOpenKey);
  return pending;
}
