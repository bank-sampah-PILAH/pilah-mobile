import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// Centred placeholder for an empty list.
///
/// Always scrollable, even though the content never overflows: these sit inside
/// a [RefreshIndicator], which only receives the pull gesture from a scrollable
/// descendant. A plain [Center] would leave the user stranded on an empty screen
/// with no way to check the backend for new data.
///
/// Must be given a bounded height (e.g. inside an [Expanded]) — it expands to
/// fill the viewport so the content stays vertically centred.
class EmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppColors.greenDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyle.title1.copyWith(
                color: AppColors.black,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyle.small.copyWith(
                  color: AppColors.grey100,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
