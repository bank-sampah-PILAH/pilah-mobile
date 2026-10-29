import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

void main() {
  test('the weights are the four faces of the bundled Poppins', () {
    expect(AppFontWeight.regular, FontWeight.w400);
    expect(AppFontWeight.medium, FontWeight.w500);
    expect(AppFontWeight.semibold, FontWeight.w600);
    expect(AppFontWeight.bold, FontWeight.w700);
  });

  test('bold is the same weight Flutter calls FontWeight.bold', () {
    expect(AppFontWeight.bold, FontWeight.bold);
    expect(AppFontWeight.regular, FontWeight.normal);
  });
}
