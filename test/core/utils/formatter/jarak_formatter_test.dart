import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/jarak_formatter.dart';

void main() {
  test('under a kilometer renders as whole meters', () {
    expect(formatJarakId(0.85), '850 m');
    expect(formatJarakId(0.0004), '0 m');
    expect(formatJarakId(0.999), '999 m');
  });

  test('a kilometer or more renders with one decimal', () {
    expect(formatJarakId(1), '1.0 km');
    expect(formatJarakId(1.23), '1.2 km');
    expect(formatJarakId(25), '25.0 km');
  });
}
