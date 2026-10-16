import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/cubit/pengumuman_cubit.dart';
import 'package:pilah_mobile/features/pengumuman/presentation/pages/pengumuman_form_page.dart';

import '../../../../support/pengumuman_support.dart';
import '../../../../support/stub_api.dart';

Widget _page(StubApi api) {
  return BlocProvider<PengumumanCubit>.value(
    value: buildPengumumanCubit(api),
    child: const MaterialApp(home: PengumumanFormPage()),
  );
}

void main() {
  late StubApi api;

  setUp(() {
    api = StubApi();
    api.on('POST', '/api/v1/pengumuman', json: {
      'id': '9',
      'bank_sampah_id': 'bank-1',
      'judul': 'x',
      'isi': 'x',
      'status': 'draft',
    });
    api.on('GET', '/api/v1/pengumuman',
        json: {'count': 0, 'next': null, 'results': []});
  });

  // The form and its action bar must both be on screen for the taps below.
  Future<void> tallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('empty fields show the validation message and send nothing',
      (tester) async {
    await tallViewport(tester);
    await tester.pumpWidget(_page(api));

    await tester.tap(find.text('Simpan Draft'));
    await tester.pump();

    expect(find.text('Judul wajib diisi.'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('a filled form posts the trimmed judul as a draft',
      (tester) async {
    await tallViewport(tester);
    await tester.pumpWidget(_page(api));

    // Fields appear in order: judul, then the isi paragraph.
    await tester.enterText(find.byType(TextFormField).at(0), '  Judul Uji  ');
    await tester.enterText(find.byType(TextFormField).at(1), 'Isi.');
    await tester.tap(find.text('Simpan Draft'));
    await tester.pumpAndSettle();

    expect(
      api.requests.any(
          (call) => call.method == 'POST' && call.path == '/api/v1/pengumuman'),
      isTrue,
    );
    expect(
        api.requests.where((call) => call.method == 'POST').last.json['judul'],
        'Judul Uji');
  });
}
