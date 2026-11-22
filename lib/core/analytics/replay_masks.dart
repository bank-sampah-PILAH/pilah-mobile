import 'package:flutter/widgets.dart';
import 'package:pilah_mobile/core/privacy/replay_privacy.dart'
    show HideInReplay;
import 'package:posthog_flutter/posthog_flutter.dart';

/// Font families Flutter draws an [Icon] with. A glyph from these fonts is a
/// fixed symbol, never something a pengurus typed or the server sent.
const _iconFontFamilies = {
  'MaterialIcons',
  'packages/cupertino_icons/CupertinoIcons'
};

/// The one place that says what the screen recording hides, so the mobile and
/// the web client cannot drift apart: every text and image, except the icons.
PostHogSessionReplayConfig maskedReplayConfig() => PostHogSessionReplayConfig()
  ..maskAllTexts = true
  ..maskAllImages = true
  ..textMaskPolicy = replayTextMask;

/// What the recording hides inside a text: everything except icon glyphs.
///
/// Flutter paints an icon as a one-character text, so hiding every text also
/// hid every icon, which made the navigation and buttons unreadable. An icon
/// chosen from data (a gender, an approval status) must still be wrapped in
/// [HideInReplay], which wins over this policy.
PostHogTextMask replayTextMask(String text, Widget widget) {
  if (widget is RichText) {
    final span = widget.text;
    final family = span.style?.fontFamily;
    if (span is TextSpan &&
        family != null &&
        _iconFontFamilies.contains(family)) {
      return const PostHogTextMask.none();
    }
  }
  return const PostHogTextMask.all();
}
