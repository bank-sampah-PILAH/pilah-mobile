import 'package:flutter/widgets.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

// What a screen says about itself to the screen recording. A screen, a widget of
// the design kit or a feature page imports this file, never the analytics code:
// whether and how the recording is made stays in `core/analytics`, and this is
// the one file that knows which package draws the masks.

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

/// A [Text] of fixed wording that the screen recording shows: the same as
/// `RevealInReplay(child: Text(...))`, for the common case of one text.
///
/// The same rule applies as for [RevealInReplay]: never use it for anything
/// that can hold what a pengurus typed or what came from the server.
class FixedText extends StatelessWidget {
  const FixedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => RevealInReplay(
        child: Text(
          data,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap,
        ),
      );
}

/// Hides [child] in the screen recording even though it is not text or an
/// image, such as a chart drawn on a canvas, or an icon chosen from data.
class HideInReplay extends StatelessWidget {
  const HideInReplay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PostHogMaskWidget(child: child);
}
