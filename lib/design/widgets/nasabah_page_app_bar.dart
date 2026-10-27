import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';

/// The app bar of a Nasabah page: a white bar with a 20 semibold title.
///
/// A page reached from another one passes [showBack] for a back arrow; the tabs
/// of the bottom bar do not.
class NasabahPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NasabahPageAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;
  final List<Widget> actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        leading: showBack ? const BackButton() : null,
        backgroundColor: NasabahStyle.background,
        foregroundColor: NasabahStyle.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: NasabahStyle.text(20, weight: FontWeight.w600),
        ),
        actions: actions,
      );
}
