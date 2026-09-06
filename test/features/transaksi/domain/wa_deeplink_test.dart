import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/profile/domain/wa_template_preview.dart';
import 'package:pilah_mobile/features/transaksi/domain/wa_deeplink.dart';

const _items = [
  WaSetoranItem(namaSampah: 'Plastik PET', berat: 5.2),
  WaSetoranItem(namaSampah: 'Kertas kardus', berat: 2.0),
];

/// The message the sample setoran is expected to produce, character for
/// character. Kept as one literal rather than assembled from parts so a stray
/// edit to the wording or the line breaks fails here loudly.
const _expectedMessage = 'Halo Budi Susanto 👋\n'
    'Setoran sampahmu sudah berhasil kami catat! '
    'Berikut adalah rincian setoran sampah hari ini:\n'
    '- Plastik PET 5,2 kg\n'
    '- Kertas kardus 2 kg\n'
    'Terima kasih atas kontribusimu untuk lingkungan yang lebih bersih 🌱';

void main() {
  group('normalizeWaPhone', () {
    test('swaps a national leading 0 for the country code', () {
      expect(normalizeWaPhone('081234567890'), '6281234567890');
    });

    test('strips spaces, dashes and the + sign', () {
      expect(normalizeWaPhone('0812-3456-7890'), '6281234567890');
      expect(normalizeWaPhone('+62 812-3456-7890'), '6281234567890');
      expect(normalizeWaPhone(' (0812) 3456.7890 '), '6281234567890');
    });

    test('leaves an already country-coded number alone', () {
      expect(normalizeWaPhone('6281234567890'), '6281234567890');
      expect(normalizeWaPhone('+6281234567890'), '6281234567890');
    });

    test(
        'collapses the double prefix left by a 0-prefixed entry in a '
        '+62 field', () {
      // The nasabah forms save '+62' + whatever was typed, so a user who typed
      // their number with the leading 0 is stored as +620812…. Indonesian
      // numbers never have a 0 straight after the country code, so this is
      // always the double-prefix artefact and never a real number.
      expect(normalizeWaPhone('+620812345678'), '62812345678');
      expect(normalizeWaPhone('620812345678'), '62812345678');
    });

    test('assumes a bare national number is Indonesian', () {
      expect(normalizeWaPhone('81234567890'), '6281234567890');
    });

    test('returns empty when there is nothing to dial', () {
      expect(normalizeWaPhone(''), '');
      expect(normalizeWaPhone('-'), '');
      expect(normalizeWaPhone('   '), '');
    });
  });

  group('buildWaSetoranMessage', () {
    test('renders the approved template verbatim', () {
      expect(
        buildWaSetoranMessage(nama: 'Budi Susanto', items: _items),
        _expectedMessage,
      );
    });

    test('formats weights the way the rest of the app does', () {
      final message = buildWaSetoranMessage(
        nama: 'Budi',
        items: const [
          WaSetoranItem(namaSampah: 'Plastik PET', berat: 5.2),
          WaSetoranItem(namaSampah: 'Botol', berat: 2.0),
          WaSetoranItem(namaSampah: 'Kaleng', berat: 0.05),
        ],
      );

      expect(
        message,
        contains('- Plastik PET 5,2 kg'),
        reason: 'weights use a comma decimal, matching WeightFormatter',
      );
      expect(
        message,
        contains('- Botol 2 kg'),
        reason: 'a whole number drops the trailing ",0"',
      );
      expect(message, contains('- Kaleng 0,05 kg'));
    });

    test('gives every item its own line', () {
      final lines =
          buildWaSetoranMessage(nama: 'Budi', items: _items).split('\n');

      expect(lines, hasLength(5));
      expect(lines.where((l) => l.startsWith('- ')), hasLength(2));
    });

    test('keeps the item list identical to the preview in Pengaturan Umum', () {
      // The pengelola is shown a preview of this template in profile settings;
      // if the two ever drift, they are promising their nasabah a message the
      // app does not actually send. hargaPerKg is irrelevant to {daftar_item}.
      final previewList = buildDaftarItem(const [
        WaPreviewItem(namaSampah: 'Plastik PET', berat: 5.2, hargaPerKg: 0),
        WaPreviewItem(namaSampah: 'Kertas kardus', berat: 2.0, hargaPerKg: 0),
      ]);

      expect(
        buildWaSetoranMessage(nama: 'Budi Susanto', items: _items),
        contains(previewList),
      );
    });

    test('omits prices — the template only reports weights', () {
      final message = buildWaSetoranMessage(nama: 'Budi', items: _items);

      expect(message, isNot(contains('Rp')));
      expect(message, isNot(contains('Saldo')));
    });
  });

  group('buildWaSetoranLink', () {
    Uri link(
            {String phone = '0812-3456-7890',
            List<WaSetoranItem> items = _items}) =>
        buildWaSetoranLink(phone: phone, nama: 'Budi Susanto', items: items);

    test('targets wa.me with the normalized number', () {
      final uri = link();

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/6281234567890');
    });

    test('falls back to the contact picker when the nasabah has no number', () {
      // wa.me with no number opens WhatsApp's picker with the text pre-filled —
      // still useful, and better than throwing at the pengelola.
      expect(link(phone: '').toString(), startsWith('https://wa.me/?text='));
    });

    test('round-trips the message through the query string', () {
      expect(link().queryParameters['text'], _expectedMessage);
    });

    test('escapes the line breaks instead of emitting them raw', () {
      final raw = link().toString();

      expect(raw, contains('%0A'), reason: 'newlines survive as %0A');
      expect(raw, isNot(contains('\n')));
    });

    test('escapes spaces as %20 rather than +', () {
      final raw = link().toString();

      expect(raw, contains('%20'));
      expect(
        raw,
        isNot(contains(' ')),
        reason: 'a raw space would truncate the link in most WhatsApp clients',
      );
    });

    test('percent-encodes the emoji as UTF-8', () {
      final raw = link().toString();

      expect(raw, contains('%F0%9F%91%8B'), reason: '👋 in the greeting');
      expect(raw, contains('%F0%9F%8C%B1'), reason: '🌱 in the sign-off');
      expect(raw, isNot(contains('👋')));
      expect(raw, isNot(contains('🌱')));
    });

    test('keeps a literal + in a waste name from decoding back as a space', () {
      // This is why the text is escaped with Uri.encodeComponent instead of
      // being handed to Uri(queryParameters:), which would encode spaces as '+'
      // and make the two indistinguishable on the way back out.
      final uri = link(
        items: const [WaSetoranItem(namaSampah: 'Plastik PET+HDPE', berat: 1)],
      );

      expect(uri.toString(), contains('%2B'));
      expect(uri.queryParameters['text'], contains('Plastik PET+HDPE'));
    });
  });

  group('custom templates', () {
    String render(String? template,
            {int total = 0, int saldo = 0, DateTime? tanggal}) =>
        buildWaSetoranMessage(
          nama: 'Budi Susanto',
          items: _items,
          customTemplate: template,
          total: total,
          saldo: saldo,
          tanggal: tanggal,
        );

    test('falls back to the default when no template is configured', () {
      expect(render(null), _expectedMessage);
    });

    test('falls back to the default when the template is blank', () {
      // An emptied editor field reaches here as '' (or whitespace after a
      // stray newline). Sending that verbatim would deliver an empty WhatsApp
      // draft, so it is treated as "no template".
      expect(render(''), _expectedMessage);
      expect(render('   \n  '), _expectedMessage);
    });

    test('injects the nasabah name', () {
      expect(render('Halo {Nama}!'), 'Halo Budi Susanto!');
    });

    test('injects the transaction totals with rupiah grouping', () {
      expect(render('Total {Total}', total: 15600), 'Total Rp 15.600');
      expect(render('Saldo {Saldo}', saldo: 125000), 'Saldo Rp 125.000');
    });

    test('does not double up a "Rp" the pengelola typed themselves', () {
      expect(render('Total: Rp {Total}', total: 15600), 'Total: Rp 15.600');
      expect(render('Saldo: Rp{Saldo}', saldo: 125000), 'Saldo: Rp 125.000');
    });

    test('injects the transaction date in Indonesian', () {
      expect(
        render('Tanggal {Tanggal}', tanggal: DateTime(2026, 7, 24)),
        'Tanggal 24 Juli 2026',
      );
    });

    test('injects {daftar_item} as name and weight only', () {
      expect(
        render('{daftar_item}'),
        '- Plastik PET 5,2 kg\n- Kertas kardus 2 kg',
      );
    });

    test('injects {daftar_item_harga} with the price breakdown', () {
      final message = buildWaSetoranMessage(
        nama: 'Budi',
        customTemplate: '{daftar_item_harga}',
        items: const [
          WaSetoranItem(
              namaSampah: 'Plastik PET', berat: 5.2, hargaPerKg: 2500),
        ],
      );

      expect(message, '- Plastik PET 5,2 kg x Rp 2.500 = Rp 13.000');
    });

    test('does not let {daftar_item} partially consume {daftar_item_harga}',
        () {
      // '{daftar_item}' is a prefix of '{daftar_item_harga}'. Replacing the
      // short token first would leave a dangling '_harga}' in the message.
      final message = buildWaSetoranMessage(
        nama: 'Budi',
        customTemplate: '{daftar_item}\n--\n{daftar_item_harga}',
        items: const [
          WaSetoranItem(namaSampah: 'Botol', berat: 2.0, hargaPerKg: 1000),
        ],
      );

      expect(message, '- Botol 2 kg\n--\n- Botol 2 kg x Rp 1.000 = Rp 2.000');
      expect(message, isNot(contains('_harga')));
    });

    test('leaves no unresolved variable behind', () {
      final message = render(
        'Halo {Nama} {Tanggal} {Total} {Saldo}\n{daftar_item}\n{daftar_item_harga}',
        total: 15600,
        saldo: 125000,
        tanggal: DateTime(2026, 7, 24),
      );

      expect(
        RegExp(r'\{[A-Za-z_]+\}').hasMatch(message),
        isFalse,
        reason: 'a leftover token would be delivered to the nasabah verbatim',
      );
    });

    test('renders exactly what the profile preview showed the pengelola', () {
      // The whole point of sharing one renderer: a pengelola edits their
      // template against the live preview, so the same template and the same
      // data must produce the same string on both paths. If this ever fails,
      // the preview is lying about what the nasabah receives.
      const template =
          'Halo {Nama}, total Rp {Total}, saldo Rp {Saldo}, {Tanggal}\n'
          '{daftar_item}\n{daftar_item_harga}';
      final tanggal = DateTime(2026, 7, 24);

      expect(
        buildWaSetoranMessage(
          nama: 'Budi Santoso',
          items: kWaPreviewItems,
          customTemplate: template,
          total: 15600,
          saldo: 125000,
          tanggal: tanggal,
        ),
        renderWaPreview(template, now: tanggal),
      );
    });

    test('a custom template still survives URL encoding intact', () {
      final uri = buildWaSetoranLink(
        phone: '0812-3456-7890',
        nama: 'Budi Susanto',
        items: _items,
        customTemplate:
            'Halo {Nama} ✨\nRincian:\n{daftar_item}\nTotal Rp {Total}',
        total: 15600,
      );

      expect(uri.toString(), isNot(contains('\n')));
      expect(uri.toString(), isNot(contains(' ')));
      expect(
        uri.queryParameters['text'],
        'Halo Budi Susanto ✨\n'
        'Rincian:\n'
        '- Plastik PET 5,2 kg\n'
        '- Kertas kardus 2 kg\n'
        'Total Rp 15.600',
      );
    });
  });
}
