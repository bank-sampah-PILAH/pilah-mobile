@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:pilah_mobile/core/analytics/consent_revocation_channel_web.dart';

void main() {
  test('a withdrawal reaches another channel of the same name, not the sender',
      () async {
    final sender = createConsentRevocationChannel(name: 'consent_test');
    final otherTab = createConsentRevocationChannel(name: 'consent_test');
    addTearDown(sender.close);
    addTearDown(otherTab.close);
    final heardBySender = <String>[];
    sender.revoked.listen(heardBySender.add);

    final heard = otherTab.revoked.first;
    sender.announce('u1');

    expect(await heard.timeout(const Duration(seconds: 5)), 'u1');
    expect(heardBySender, isEmpty);
  });
}
