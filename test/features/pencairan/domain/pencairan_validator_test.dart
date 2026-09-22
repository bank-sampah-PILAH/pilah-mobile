import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/pencairan/domain/pencairan_validator.dart';

void main() {
  group('PencairanValidator.nominal', () {
    test('accepts a nominal within the saldo', () {
      expect(PencairanValidator.nominal(200000, saldo: 465600), isNull);
    });

    test('accepts a nominal equal to the saldo', () {
      expect(PencairanValidator.nominal(465600, saldo: 465600), isNull);
    });

    test('requires a nominal', () {
      expect(
        PencairanValidator.nominal(null, saldo: 465600),
        'Nominal wajib diisi',
      );
    });

    test('rejects zero and negative nominals', () {
      expect(
        PencairanValidator.nominal(0, saldo: 465600),
        'Nominal harus lebih dari nol',
      );
      expect(
        PencairanValidator.nominal(-1000, saldo: 465600),
        'Nominal harus lebih dari nol',
      );
    });

    test('rejects a nominal above the saldo with the maximum', () {
      expect(
        PencairanValidator.nominal(465601, saldo: 465600),
        'Maksimal Rp 465.600',
      );
    });
  });
}
