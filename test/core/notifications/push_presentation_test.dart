import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/notifications/push_presentation.dart';

void main() {
  test(
      'shows foreground messages and opens history on tap, then stops listening',
      () async {
    final foreground = StreamController<String>.broadcast();
    final opened = StreamController<void>.broadcast();
    final shown = <String>[];
    var opens = 0;
    final presentation = PushPresentation<String>(
      foreground: foreground.stream,
      opened: opened.stream,
      initialOpen: () async => true,
      show: shown.add,
      open: () => opens++,
    );
    await presentation.start();
    foreground.add('Jadwal baru');
    opened.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(shown, ['Jadwal baru']);
    expect(opens, 2);
    await presentation.stop();
    foreground.add('ignored');
    opened.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(shown, ['Jadwal baru']);
    expect(opens, 2);
    await foreground.close();
    await opened.close();
  });
}
