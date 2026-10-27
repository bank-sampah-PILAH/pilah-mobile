import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/nasabah/presentation/widgets/nasabah_search_bar.dart';

void main() {
  testWidgets('shows its hint and reports what is typed', (tester) async {
    String? typed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        // A non-const instance so the constructor itself runs.
        // ignore: prefer_const_constructors
        body: NasabahSearchBar(onChanged: (v) => typed = v),
      ),
    ));
    expect(find.text('Cari nama atau nomor...'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'budi');

    expect(typed, 'budi');
  });

  testWidgets('works without a listener', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: NasabahSearchBar()),
    ));

    await tester.enterText(find.byType(TextField), 'x');

    expect(find.text('x'), findsOneWidget);
  });
}
