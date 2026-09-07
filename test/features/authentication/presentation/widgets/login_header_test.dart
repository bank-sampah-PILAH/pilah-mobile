import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_header.dart';

/// The logo's aspect ratio, read from the asset rather than hard-coded.
///
/// An earlier version of this test pinned the ratio of the logo that happened
/// to be checked in at the time, and broke the moment the mark was redrawn —
/// reporting a failure when nothing was actually wrong. The invariant worth
/// protecting is that the logo is never *stretched*, whatever it looks like.
double _logoAspectRatio() {
  final svg = File('assets/svg/logo.svg').readAsStringSync();
  final viewBox = RegExp(r'viewBox="0 0 ([\d.]+) ([\d.]+)"').firstMatch(svg);
  expect(viewBox, isNotNull, reason: 'logo.svg should declare a viewBox');
  return double.parse(viewBox!.group(1)!) / double.parse(viewBox.group(2)!);
}

void main() {
  group('LoginHeader', () {
    testWidgets('renders the SVG logo and no longer the checkmark',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: LoginHeader())),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(
        find.byIcon(Icons.check_circle_outline),
        findsNothing,
        reason: 'the placeholder checkmark should be gone',
      );
      expect(find.text('PILAH'), findsOneWidget);
    });

    testWidgets('the logo asset actually loads and lays out without overflow',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: LoginHeader())),
      ));
      await tester.pumpAndSettle();

      // A missing/unregistered asset or malformed SVG surfaces as a pumped
      // exception rather than a build failure, so assert on it explicitly.
      expect(tester.takeException(), isNull);

      // Height is pinned; width must follow the viewBox rather than stretch.
      final size = tester.getSize(find.byType(SvgPicture));
      expect(size.height, 96);
      expect(size.width, closeTo(96 * _logoAspectRatio(), 1.0));
    });
  });
}
