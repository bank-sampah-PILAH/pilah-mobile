@TestOn('browser')
library;

import 'package:pilah_mobile/core/notifications/web_push_open_web.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

const _openKey = 'pilah-notification-open';

void main() {
  setUp(() => web.window.sessionStorage.removeItem(_openKey));

  test('consumes a pending notification open once', () {
    web.window.sessionStorage.setItem(_openKey, '1');

    expect(takeWebPushOpen(), isTrue);
    expect(takeWebPushOpen(), isFalse);
  });

  test('emits only when the notification open is pending', () async {
    final opened = webPushOpens.first;
    web.window.dispatchEvent(web.Event(_openKey));
    expect(takeWebPushOpen(), isFalse);

    web.window.sessionStorage.setItem(_openKey, '1');
    web.window.dispatchEvent(web.Event(_openKey));
    await expectLater(opened, completion(null));
    expect(takeWebPushOpen(), isFalse);
  });
}
