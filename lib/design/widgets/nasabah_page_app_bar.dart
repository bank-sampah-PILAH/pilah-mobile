import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/font_size.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// The app bar of a Nasabah page: a white bar with a 20 semibold title.
///
/// A page reached from another one passes [showBack] for a back arrow; the tabs
/// of the bottom bar do not.
class NasabahPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NasabahPageAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;

  /// A second line under the title, such as the item a page is about.
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget get _titleText => Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            NasabahStyle.text(AppFontSize.xxl, weight: AppFontWeight.semibold),
      );

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: false,
        leading: showBack ? const BackButton() : null,
        backgroundColor: NasabahStyle.background,
        foregroundColor: NasabahStyle.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: subtitle == null
            ? _titleText
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleText,
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NasabahStyle.text(AppFontSize.sm),
                  ),
                ],
              ),
        actions: actions,
      );
}
