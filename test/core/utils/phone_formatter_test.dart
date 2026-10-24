import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/formatter/phone_formatter.dart';

TextEditingValue _typed(String text, {int? caret}) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );

void main() {
  final formatter = PhoneFormatter();

  TextEditingValue format(String text, {int? caret}) => formatter
      .formatEditUpdate(TextEditingValue.empty, _typed(text, caret: caret));

  test('groups the digits in fours', () {
    expect(format('081234567890').text, '0812-3456-7890');
  });

  test('adds no trailing separator on a full group', () {
    expect(format('0812').text, '0812');
    expect(format('08123').text, '0812-3');
  });

  test('keeps the caret at the end of the formatted text', () {
    final value = format('081234567');

    expect(value.text, '0812-3456-7');
    expect(value.selection.baseOffset, value.text.length);
  });

  test('leaves the value untouched when the caret is at the start', () {
    final value = format('0812', caret: 0);

    expect(value.text, '0812');
    expect(value.selection.baseOffset, 0);
  });
}
