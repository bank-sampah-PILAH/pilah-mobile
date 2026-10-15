import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';

import '../../domain/model/draft_pencairan.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

class DraftStatusBadge extends StatelessWidget {
  final DraftStatus status;

  const DraftStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, text) = switch (status) {
      DraftStatus.draft => (AppColors.warningLight, AppColors.warning),
      DraftStatus.dikonfirmasi => (AppColors.greenLight, AppColors.greenDark),
      DraftStatus.dibatalkan || DraftStatus.tidakDikenal => (
          AppColors.fill,
          AppColors.inkSoft
        ),
    };
    return CustomStatusBadge(
      statusText: status.label,
      backgroundColor: background,
      textColor: text,
    );
  }
}
