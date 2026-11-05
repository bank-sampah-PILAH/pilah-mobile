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
