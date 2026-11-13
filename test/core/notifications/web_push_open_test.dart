import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/notifications/web_push_open.dart';

void main() {
  test('the native stub has no pending notification opens', () async {
    expect(await webPushOpens.isEmpty, isTrue);
    expect(takeWebPushOpen(), isFalse);
  });
}
