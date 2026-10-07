import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_status_badge.dart';

import '../../domain/model/draft_pencairan.dart';

class DraftStatusBadge extends StatelessWidget {
  final DraftStatus status;

  const DraftStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, text) = switch (status) {
      DraftStatus.draft => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      DraftStatus.dikonfirmasi => (
          const Color(0xFFDCFCE7),
          const Color(0xFF166534)
        ),
      DraftStatus.dibatalkan => (
          const Color(0xFFF3F4F6),
          const Color(0xFF4B5563)
        ),
    };
    return CustomStatusBadge(
      statusText: status.label,
      backgroundColor: background,
      textColor: text,
    );
  }
}
