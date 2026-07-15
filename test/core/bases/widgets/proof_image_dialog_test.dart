import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/bases/widgets/proof_image_dialog.dart';

/// Pumps a host with a button that opens the dialog for [imageUrl].
///
/// Tears the tree down first so repeated calls within one test start from a
/// fresh Navigator, rather than tapping at a button sitting behind the previous
/// dialog's barrier.
Future<void> _openDialog(WidgetTester tester, {String? imageUrl}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showProofImageDialog(context, imageUrl: imageUrl),
          child: const Text('Lihat Bukti'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Lihat Bukti'));
  await tester.pump();
}

/// The URL every rendered [Image.network] in the tree is pointing at.
List<String> _renderedNetworkUrls(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((i) => i.image)
    .whereType<NetworkImage>()
    .map((n) => n.url)
    .toList();

void main() {
  group('showProofImageDialog', () {
    testWidgets('with no photo on record, shows nothing rather than a stand-in',
        (tester) async {
      await _openDialog(tester, imageUrl: null);

      expect(find.text('Tidak ada foto kegiatan'), findsOneWidget);
      expect(
        _renderedNetworkUrls(tester),
        isEmpty,
        reason: 'a superadmin must never approve against a stand-in image',
      );
    });

    testWidgets('an empty url counts as no photo, not a broken one',
        (tester) async {
      await _openDialog(tester, imageUrl: '   ');

      expect(find.text('Tidak ada foto kegiatan'), findsOneWidget);
      expect(_renderedNetworkUrls(tester), isEmpty);
    });

    testWidgets('with a real url, loads exactly that url', (tester) async {
      const url = 'https://storage.googleapis.com/pilah/kegiatan/bukti.jpg';
      await _openDialog(tester, imageUrl: url);

      expect(_renderedNetworkUrls(tester), [url]);
      expect(find.text('Tidak ada foto kegiatan'), findsNothing);
    });

    testWidgets('never falls back to a stock photo service', (tester) async {
      for (final input in <String?>[null, '', '  ']) {
        await _openDialog(tester, imageUrl: input);
        final urls = _renderedNetworkUrls(tester).join(' ');
        expect(
          urls.contains('picsum') || urls.contains('placeholder'),
          isFalse,
          reason: 'the picsum dummy must not come back for input: $input',
        );
      }
    });
  });
}
