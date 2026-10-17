import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';

class NasabahPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NasabahPageAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBackButton = false,
  });

  final String title;
  final List<Widget> actions;

  /// Grey-tile back button in the leading slot, same idiom as the profile
  /// header — for pages pushed on top of a tab (list/detail), not tab roots.
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(Icons.arrow_back, color: Colors.grey[800], size: 20),
                ),
              )
            : null,
        backgroundColor: NasabahStyle.background,
        foregroundColor: NasabahStyle.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title:
            Text(title, style: NasabahStyle.text(20, weight: FontWeight.w600)),
        actions: actions,
      );
}
