import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';

class NasabahPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NasabahPageAppBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: NasabahStyle.background,
        foregroundColor: NasabahStyle.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title:
            Text(title, style: NasabahStyle.text(20, weight: FontWeight.w600)),
        actions: actions,
      );
}
