import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/radius.dart';

/// The surface of a bottom sheet: a white panel with rounded top corners that
/// rises above the keyboard, keeps clear of the system bar and scrolls when its
/// [child] is taller than the screen.
///
/// Put the sheet's own `Column` in [child]; the handle and the header belong
/// to it, so a sheet that is a form can wrap the column in a `Form` first.
class AppSheetContainer extends StatelessWidget {
  const AppSheetContainer({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 24),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @visibleForTesting
  static const surfaceKey = Key('app-sheet-container-surface');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        key: surfaceKey,
        decoration: BoxDecoration(
          color: color,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(padding: padding, child: child),
        ),
      ),
    );
  }
}
