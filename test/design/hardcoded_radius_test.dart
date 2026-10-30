import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps a corner radius from being written as a number outside `lib/design/`.
///
/// `AppRadius` (4, 8, 12, 16, 24 and `pill`) is the scale of the app, so a
/// screen that writes `BorderRadius.circular(14)` is inventing a shape the
/// design does not have. There is no baseline: a bare number fails.
///
/// `Radius.circular(` also covers `BorderRadius.circular(`. A token such as
/// `AppRadius.md` starts with a letter, so it is not counted.
final _literal = RegExp(r'Radius\.circular\(\s*[0-9]');

Map<String, int> _scan([Directory? root]) {
  final found = <String, int>{};
  final dir = root ?? Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    final relative = path.substring(dir.path.length + 1);
    if (relative == 'design/constants/radius.dart') continue;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    final count = _literal.allMatches(entity.readAsStringSync()).length;
    if (count > 0) found[path] = count;
  }
  return found;
}

void main() {
  test('the pattern counts a number but not a token', () {
    expect(_literal.hasMatch('BorderRadius.circular(12)'), isTrue);
    expect(_literal.hasMatch('Radius.circular( 24 )'), isTrue);
    expect(_literal.hasMatch('BorderRadius.circular(AppRadius.md)'), isFalse);
    expect(_literal.hasMatch('Radius.circular(AppRadius.xl)'), isFalse);
  });

  test('only the radius scale itself may hold a bare number', () {
    final root = Directory.systemTemp.createTempSync('radius_guard');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final path in [
      'design/constants/radius.dart',
      'features/radius.dart'
    ]) {
      File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync('final r = BorderRadius.circular(10);');
    }

    expect(_scan(root).keys,
        ['${root.path.replaceAll(r'\', '/')}/features/radius.dart']);
  });

  test('no file writes a corner radius as a bare number', () {
    final problems = [
      for (final entry in _scan().entries)
        '${entry.key}: ${entry.value} bare radii',
    ];

    expect(
      problems,
      isEmpty,
      reason: 'Use AppRadius.xs, sm, md, lg, xl or pill '
          '(lib/design/constants/radius.dart). If the design needs a new '
          'step, add it there instead of writing a number in a screen.',
    );
  });
}
