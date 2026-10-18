import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(
      body: AppPageHeader(
        title: 'Daftar Nasabah',
        subtitle: Text('3 nasabah aktif'),
        search: TextField(key: Key('cari')),
        actions: [Text('Aksi')],
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
}
