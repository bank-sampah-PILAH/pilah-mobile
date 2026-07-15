import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Runs [action], but does not resolve until at least [minimum] has passed.
///
/// The wait runs *alongside* [action] rather than after it, so this only ever
/// stretches something faster than [minimum] — an action that already takes
/// longer is handed back the moment it finishes.
Future<void> withMinimumDuration(
  Future<void> Function() action,
  Duration minimum,
) async {
  await Future.wait([action(), Future<void>.delayed(minimum)]);
}

/// The app's pull-to-refresh wrapper: brand colour, plus a floor on how briefly
/// the spinner may appear.
///
/// Requests against a local backend or fast Wi-Fi return in ~30-80ms — quicker
/// than the eye can register. The spinner appears and vanishes within a couple
/// of frames, so the gesture reads as dead and users pull again. Holding it for
/// [minimumSpinnerHold] makes the refresh perceptible without making a genuinely
/// slow fetch any slower: the delay runs *alongside* the fetch, not after it, so
/// anything taking longer than the floor is unaffected.
///
/// Use this instead of a bare [RefreshIndicator] so every screen refreshes with
/// the same feel.
class AppRefreshIndicator extends StatelessWidget {
  @visibleForTesting
  static const minimumSpinnerHold = Duration(milliseconds: 500);

  /// Called on pull. Must complete when the underlying fetch does — the spinner
  /// stays up until it resolves.
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => withMinimumDuration(onRefresh, minimumSpinnerHold),
      color: AppColors.greenDark,
      child: child,
    );
  }
}
