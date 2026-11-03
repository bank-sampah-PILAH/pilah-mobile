import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/transaksi/presentation/widgets/setoran_form_view.dart';

/// The tutorial tooltip is as wide as its longest line, and the package lays it
/// out against the window rather than the panel the form sits in. A long
/// one-line description therefore pokes out of a 560 px side sheet.
void main() {
  test('breaks a long sentence at word boundaries within the limit', () {
    final wrapped = wrapTutorialText(
      'Ketuk kolom ini untuk memilih nasabah. Untuk mengganti, '
      'ketuk lagi nama nasabah yang tampil.',
      maxChars: 40,
    );

    final lines = wrapped.split('\n');
    expect(lines.length, greaterThan(1));
    expect(lines.every((l) => l.length <= 40), isTrue);
    expect(
        wrapped.replaceAll('\n', ' '),
        'Ketuk kolom ini untuk memilih nasabah. Untuk mengganti, '
        'ketuk lagi nama nasabah yang tampil.');
  });

  test('leaves a short sentence on one line', () {
    expect(wrapTutorialText('Cukup pendek.', maxChars: 40), 'Cukup pendek.');
  });

  test('keeps a word longer than the limit whole instead of cutting it', () {
    expect(
      wrapTutorialText('a ${'x' * 50} b', maxChars: 10),
      'a\n${'x' * 50}\nb',
    );
  });
}
