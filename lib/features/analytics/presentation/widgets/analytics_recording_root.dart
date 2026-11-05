import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/screen_recorder.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';

/// Puts the screen recorder around the app once analytics has started.
///
/// The recorder can only be added after the pengurus has agreed, which is
/// after the app is already running. The app sits under a [GlobalKey], so
/// Flutter moves it into the recorder instead of building it again: the
/// pengurus keeps their screen, their form and their place in the app.
class AnalyticsRecordingRoot extends ConsumerStatefulWidget {
  const AnalyticsRecordingRoot({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AnalyticsRecordingRoot> createState() =>
      _AnalyticsRecordingRootState();
}

class _AnalyticsRecordingRootState
    extends ConsumerState<AnalyticsRecordingRoot> {
  final _appKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Agreeing or withdrawing starts or stops the client, so the choice is
    // what makes the recorder appear.
    ref.watch(analyticsConsentProvider);
    final app = KeyedSubtree(key: _appKey, child: widget.child);
    final client = ref.read(analyticsClientProvider);
    final Object recorder = client;
    return recorder is ScreenRecorder ? recorder.wrapApp(app) : app;
  }
}
