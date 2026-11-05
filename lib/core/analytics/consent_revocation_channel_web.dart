import 'dart:async';
import 'dart:js_interop';

import 'package:pilah_mobile/core/analytics/consent_revocation_channel.dart';
import 'package:web/web.dart' as web;

/// Tabs of the same site tell each other about a withdrawal through a
/// `BroadcastChannel`, which never delivers a message to the tab that sent it.
ConsentRevocationChannel createConsentRevocationChannel({
  String name = 'pilah_analytics_consent',
}) =>
    _BroadcastRevocationChannel(name);

class _BroadcastRevocationChannel implements ConsentRevocationChannel {
  _BroadcastRevocationChannel(String name)
      : _channel = web.BroadcastChannel(name) {
    _channel.onmessage = ((web.MessageEvent event) {
      final data = event.data.dartify();
      if (data is String) _revoked.add(data);
    }).toJS;
  }

  final web.BroadcastChannel _channel;
  final _revoked = StreamController<String>.broadcast();

  @override
  void announce(String userId) => _channel.postMessage(userId.toJS);

  @override
  Stream<String> get revoked => _revoked.stream;

  @override
  void close() {
    _channel.close();
    _revoked.close();
  }
}
