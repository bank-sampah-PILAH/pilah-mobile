import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Reveals [child] in the screen recording of the mobile app.
///
/// The recording hides every text and image, which also hides the labels that
/// say which screen and which step a pengurus is on. Wrap a text in this only
/// when it is fixed wording of the app: a field caption, a page title, the
/// label of a button. Never wrap anything that can hold what a pengurus typed
/// or what came from the server: a name, an address, an amount, a note.
class RevealInReplay extends StatelessWidget {
  const RevealInReplay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PostHogUnmaskWidget(child: child);
}

/// Hides [child] in the screen recording even though it is not text or an
/// image, such as a chart drawn on a canvas.
class HideInReplay extends StatelessWidget {
  const HideInReplay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PostHogMaskWidget(child: child);
}

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
