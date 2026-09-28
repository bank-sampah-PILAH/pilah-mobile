import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pilah_mobile/design/constants/colors.dart';

/// Text truncated to [maxLines], with a "Lihat Selengkapnya" / "Sembunyikan"
/// toggle that appears only when the text actually overflows that limit —
/// so a long appeal message or rejection reason doesn't blow out a list of
/// otherwise-short history entries, while the full text stays one tap away.
///
/// Measures overflow via the rendered [RenderParagraph] on the frame after
/// first layout, rather than a [LayoutBuilder]: a `LayoutBuilder` can't sit
/// under an `IntrinsicHeight` ancestor (as this widget does inside
/// `ApprovalLogStep`'s timeline row) — Flutter throws on the intrinsic-size
/// query a `LayoutBuilder` requires there.
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  final _textKey = GlobalKey();
  bool _expanded = false;
  bool _overflows = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(covariant ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  void _checkOverflow() {
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (!mounted || renderObject is! RenderParagraph) return;
    final overflows = renderObject.didExceedMaxLines;
    if (overflows != _overflows) {
      setState(() => _overflows = overflows);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          key: _textKey,
          style: widget.style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        if (_overflows)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Sembunyikan' : 'Lihat Selengkapnya',
                style: (widget.style ?? const TextStyle()).copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
