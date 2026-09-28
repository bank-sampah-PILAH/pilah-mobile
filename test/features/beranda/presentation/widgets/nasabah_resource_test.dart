import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';

void main() {
  testWidgets('ignores a reload callback after its resource is disposed', (
    tester,
  ) async {
    Future<void> Function()? reload;
    var loadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: NasabahResource<int>(
          load: () async => ++loadCount,
          registerReload: (callback) => reload = callback,
          builder: (_, value) => Text('$value'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final staleReload = reload!;

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await staleReload();

    expect(loadCount, 1);
    expect(tester.takeException(), isNull);
  });
}
