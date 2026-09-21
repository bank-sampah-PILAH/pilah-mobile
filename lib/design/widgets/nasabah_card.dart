import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';

class NasabahCard extends StatelessWidget {
  const NasabahCard(
      {super.key,
      required this.child,
      this.padding = 16,
      this.radius = 16,
      this.raised = false});

  final Widget child;
  final double padding;
  final double radius;
  final bool raised;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: NasabahStyle.line),
          boxShadow: raised
              ? const [
                  BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ]
              : null,
        ),
        child: child,
      );
}
