import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';

Future<void> _pump(WidgetTester tester, double width,
    {double? boxWidth}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  const header = AppPageHeader(
    title: 'Daftar Nasabah',
    subtitle: Text('3 nasabah aktif'),
    search: TextField(key: Key('cari')),
    actions: [Text('Aksi')],
  );
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: boxWidth == null
          ? header
          : Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: boxWidth, child: header),
            ),
    ),
  ));
}

void main() {
  group('on a wide screen', () {
    testWidgets('the title, a 360 wide search and the action share one row',
        (tester) async {
      await _pump(tester, 1280);

      final title = tester.getRect(find.text('Daftar Nasabah'));
      final search = tester.getRect(find.byKey(const Key('cari')));
      final action = tester.getRect(find.text('Aksi'));
      expect(search.width, 360);
      expect(search.left, greaterThan(title.right));
      expect(action.left, greaterThan(search.right));
      expect((search.center.dy - title.center.dy).abs(), lessThan(40));
    });

    testWidgets('the subtitle sits under the title', (tester) async {
      await _pump(tester, 1280);

      expect(tester.getTopLeft(find.text('3 nasabah aktif')).dy,
          greaterThan(tester.getBottomLeft(find.text('Daftar Nasabah')).dy));
    });
  });

  testWidgets('below the wide breakpoint the search drops under the title',
      (tester) async {
    await _pump(tester, 700);

    final title = tester.getRect(find.text('Daftar Nasabah'));
    final search = tester.getRect(find.byKey(const Key('cari')));
    expect(search.top, greaterThan(title.bottom));
    expect(search.left, title.left);
  });

  testWidgets('it goes by the room it has, not the window', (tester) async {
    // A wide window whose page is split by a side panel leaves the header
    // only this much.
    await _pump(tester, 1440, boxWidth: 650);

    final title = tester.getRect(find.text('Daftar Nasabah'));
    final search = tester.getRect(find.byKey(const Key('cari')));
    expect(search.top, greaterThan(title.bottom));
    expect(tester.takeException(), isNull);
  });
}
