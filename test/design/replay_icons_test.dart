import 'package:flutter_test/flutter_test.dart';

import '../support/design_ratchet.dart';
import 'replay_icon_baseline.dart';

/// Guards the one rule the screen recording cannot enforce itself: an icon
/// that depends on data must be hidden in it.
///
/// An icon spelled `Icon(Icons.home)` is the same for everyone. An icon whose
/// glyph is a variable, a ternary or a switch may depend on the data of one
/// nasabah or one bank sampah, so each new one has to be looked at.
final _nonLiteral = RegExp(
  r'(?<![A-Za-z_])Icon\((?!\s*(?:const\s+)?(?:Icons|CupertinoIcons)\.[A-Za-z_0-9]+\s*[,)])',
);
final _hidden = RegExp(r'HideInReplay\(\s*(?:child:\s*)?(?:const\s+)?$');

/// How many icons of [source] are neither literal nor wrapped in
/// `HideInReplay`.
int unreviewedIcons(String source) {
  var count = 0;
  for (final match in _nonLiteral.allMatches(source)) {
    final before = source.substring(
      match.start < 60 ? 0 : match.start - 60,
      match.start,
    );
    if (!_hidden.hasMatch(before)) count++;
  }
  return count;
}

Map<String, int> _scan() {
  final found = <String, int>{};
  for (final source in designSources()) {
    if (source.isGenerated) continue;
    final count = unreviewedIcons(source.read());
    if (count > 0) found[source.relativePath] = count;
  }
  return found;
}

void main() {
  test('the pattern counts a computed icon but not a literal or a hidden one',
      () {
    expect(unreviewedIcons('Icon(Icons.home)'), 0);
    expect(unreviewedIcons('Icon(\n  Icons.home,\n  size: 8)'), 0);
    expect(unreviewedIcons('Icon(CupertinoIcons.back)'), 0);
    expect(unreviewedIcons('Icon(const Icons.home)'), 0);
    expect(unreviewedIcons('Icon(item.icon, size: 8)'), 1);
    expect(unreviewedIcons('Icon(ok ? Icons.a : Icons.b)'), 1);
    expect(unreviewedIcons('HideInReplay(child: Icon(item.icon))'), 0);
    expect(
        unreviewedIcons('HideInReplay(\n  child: Icon(\n    item.icon))'), 0);
    expect(unreviewedIcons('MyIcon(item.icon)'), 0);
  });

  test('no icon that may depend on data is shown in the recording unreviewed',
      () {
    final found = _scan();
    final problems = <String>[
      for (final entry in found.entries)
        if (entry.value > (replayIconBaseline[entry.key] ?? 0))
          '${entry.key}: ${entry.value} computed icon(s), '
              '${replayIconBaseline[entry.key] ?? 0} reviewed',
      for (final entry in replayIconBaseline.entries)
        if ((found[entry.key] ?? 0) < entry.value)
          '${entry.key}: baseline says ${entry.value}, found '
              '${found[entry.key] ?? 0}; lower the number',
    ];

    expect(
      problems,
      isEmpty,
      reason: 'The recording shows icons. If this icon depends on the data of '
          'a person or a bank sampah, wrap it in HideInReplay. If it does '
          'not, add it to test/design/replay_icon_baseline.dart.',
    );
  });
}
