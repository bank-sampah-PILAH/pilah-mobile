import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ban on dialogs built per screen outside `lib/design/`.
///
/// `AppDialog` (a question, or a form in a dialog), `AppIconDialog` (a decision
/// about a person or an item) and `showAppConfirmDialog` (a plain yes or no)
/// give every dialog the same title, the same buttons and the same radius. A
/// screen that builds its own `AlertDialog(...)` or `Dialog(...)` restyles all
/// three. New ones are not allowed; the existing ones are recorded per file in
/// `hardcoded_dialogs_baseline.json` and can only go down.
/// The left boundary keeps `showDialog(` and `SimpleDialog(` out of the count:
/// only the bare widgets are a dialog built by hand.
final _stock = RegExp(r'(?<![A-Za-z_])(AlertDialog|Dialog)\(');

List<String> _scan() {
  final found = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path;
    if (path.startsWith('lib/design/')) continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _stock.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found.add('$path: $count');
  }
  return found;
}

void main() {
  test('the pattern counts a dialog built by hand, not the helpers', () {
    expect(_stock.hasMatch('return AlertDialog(title: x)'), isTrue);
    expect(_stock.hasMatch('child: Dialog(child: x)'), isTrue);
    expect(_stock.hasMatch('showDialog(context: c)'), isFalse);
    expect(_stock.hasMatch('AppDialog(title: x)'), isFalse);
    expect(_stock.hasMatch('AppIconDialog(title: x)'), isFalse);
    expect(_stock.hasMatch('SimpleDialog(children: x)'), isFalse);
  });

  test('no screen uses a dialog built by hand', () {
    expect(
      _scan(),
      isEmpty,
      reason:
          'Use AppDialog, AppIconDialog, showAppConfirmDialog or AppMediaDialog (lib/design/widgets/). If the design needs another kind of dialog, add it there instead of building one in a screen.',
    );
  });
}
