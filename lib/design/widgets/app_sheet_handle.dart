import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';

/// The grey bar at the top of a bottom sheet that says it can be dragged.
///
/// `BottomSheetHeader` already shows it; use this one when a sheet lays out its
/// own header. It is decoration, so a screen reader skips it.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @visibleForTesting
  static const barKey = Key('app-sheet-handle-bar');

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Center(
        child: Container(
          key: barKey,
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}
