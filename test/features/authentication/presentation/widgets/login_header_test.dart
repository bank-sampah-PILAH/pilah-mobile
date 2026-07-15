import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/widgets/login_header.dart';

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

      // Height is pinned; width must follow the 872:913 viewBox rather than
      // being stretched.
      final size = tester.getSize(find.byType(SvgPicture));
      expect(size.height, 96);
      expect(size.width, closeTo(96 * 872 / 913, 1.0));
    });
  });
}
