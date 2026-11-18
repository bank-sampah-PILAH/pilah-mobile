import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_scrubber.dart';

void main() {
  group('ErrorScrubber.clean', () {
    test('replaces an email address', () {
      expect(
        ErrorScrubber.clean('Gagal mengirim ke budi.santoso@example.com'),
        'Gagal mengirim ke [email]',
      );
    });

    test('replaces a phone number, with or without a country code', () {
      expect(
        ErrorScrubber.clean('nomor 081234567890 dan +62 812-3456-7890'),
        'nomor [angka] dan [angka]',
      );
    });

    test('replaces a bearer token and a bare JWT', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJl';
      expect(
        ErrorScrubber.clean('Authorization: Bearer abc123.def456 gagal'),
        'Authorization: [token] gagal',
      );
      expect(ErrorScrubber.clean('token $jwt kedaluwarsa'),
          'token [token] kedaluwarsa');
    });

    test('replaces a rupiah amount', () {
      expect(
        ErrorScrubber.clean('saldo Rp 1.500.000 dan Rp250.000,50 kurang'),
        'saldo [uang] dan [uang] kurang',
      );
    });

    test('keeps the ordinary text of an error', () {
      const text = 'Bad state: No element (depth=7, status 500)';
      expect(ErrorScrubber.clean(text), text);
    });

    test('cuts a long message to 200 characters', () {
      final out = ErrorScrubber.clean('x' * 500);
      expect(out.length, ErrorScrubber.maxLength);
    });
  });
}
