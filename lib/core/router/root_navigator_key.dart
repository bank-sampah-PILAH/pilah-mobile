import 'package:flutter/widgets.dart';

/// Key on the router's root [Navigator].
///
/// It lives in its own file rather than as a private field of `AppRouterConfig`
/// so a page can reach a live navigator context *after* routing away from
/// itself — raising a toast on the screen it just sent the user to — without
/// importing the router, which imports every page straight back.
final rootNavigatorKey = GlobalKey<NavigatorState>();
