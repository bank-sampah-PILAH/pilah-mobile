import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/theme/app_theme.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('an icon-only target is read by its label, as a button',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(
      AppTapTarget(
        label: 'Hapus foto',
        onTap: () {},
        child: const Icon(Icons.close, size: 16),
      ),
    ));

    expect(
      tester.getSemantics(find.byType(AppTapTarget)),
      isSemantics(label: 'Hapus foto', isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('without a label it reads its own text', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(
      AppTapTarget(onTap: () {}, child: const Text('Lihat Selengkapnya')),
    ));

    expect(
      tester.getSemantics(find.byType(AppTapTarget)),
      isSemantics(label: 'Lihat Selengkapnya', isButton: true),
    );
    handle.dispose();
  });

  testWidgets('can report a selected state inside a group', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(
      AppTapTarget(
        selected: true,
        inGroup: true,
        onTap: () {},
        child: const Text('Laki-laki'),
      ),
    ));

    expect(
      tester.getSemantics(find.byType(AppTapTarget)),
      isSemantics(
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a small icon still gets a 48 dp hit area', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(
      AppTapTarget(
        label: 'Hapus foto',
        onTap: () {},
        child: const Icon(Icons.close, size: 16),
      ),
    ));

    expect(tester.getSize(find.byType(AppTapTarget)).height, 48);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('tapping calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      AppTapTarget(
        label: 'Buka profil',
        onTap: () => taps++,
        child: const Icon(Icons.person),
      ),
    ));

    await tester.tap(find.byType(AppTapTarget));

    expect(taps, 1);
  });
}
