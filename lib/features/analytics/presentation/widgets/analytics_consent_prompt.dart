import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/widgets/analytics_consent_dialog.dart';

/// Wraps the app's signed-in area and asks a pengurus for consent to be
/// recorded, once, the first time it applies. It passes the answer on to
/// [AnalyticsConsentController], which is what starts or stops recording.
class AnalyticsConsentPrompt extends ConsumerStatefulWidget {
  const AnalyticsConsentPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AnalyticsConsentPrompt> createState() =>
      _AnalyticsConsentPromptState();
}

class _AnalyticsConsentPromptState
    extends ConsumerState<AnalyticsConsentPrompt> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<bool>(
      analyticsNeedsPromptProvider,
      (_, needsPrompt) {
        if (needsPrompt) _ask();
      },
      fireImmediately: true,
    );
  }

  Future<void> _ask() async {
    if (_asking) return;
    _asking = true;
    // The dialog needs the Navigator below this widget, which exists only once
    // the first frame has been built.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final agreed = await showAnalyticsConsentDialog(
      context,
      recordsScreen: ref.read(analyticsClientProvider).recordsScreen,
    );
    if (!mounted) return;
    final consent = ref.read(analyticsConsentProvider.notifier);
    if (agreed == true) {
      await consent.grant();
    } else if (agreed == false) {
      await consent.deny();
    }
    _asking = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
