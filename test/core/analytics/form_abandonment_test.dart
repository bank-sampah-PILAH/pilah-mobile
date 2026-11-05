import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/form_abandonment.dart';

void main() {
  late int reports;
  late FormAbandonment form;

  setUp(() {
    reports = 0;
    form = FormAbandonment(() => reports++);
  });

  test('a form closed without saving is reported once', () {
    form.opened();

    form
      ..closed()
      ..closed();

    expect(reports, 1);
  });

  test('a form that was never opened has nothing to report', () {
    form.closed();

    expect(reports, 0);
  });

  test('a form that was saved is not reported when it closes', () {
    form
      ..opened()
      ..saved()
      ..closed();

    expect(reports, 0);
  });

  test('closing while the save is still on its way waits for the outcome', () {
    form
      ..opened()
      ..sending()
      ..closed();

    expect(reports, 0);
  });

  test('a save that lands after the form closed is not a cancellation', () {
    form
      ..opened()
      ..sending()
      ..closed()
      ..saved();

    expect(reports, 0);
  });

  test('a save that fails after the form closed makes it a cancellation', () {
    form
      ..opened()
      ..sending()
      ..closed()
      ..sendFailed();

    expect(reports, 1);
  });

  test('a save that fails while the form is open reports nothing yet', () {
    form
      ..opened()
      ..sending()
      ..sendFailed();

    expect(reports, 0);

    form.closed();

    expect(reports, 1);
  });

  test('opening the form again starts over', () {
    form
      ..opened()
      ..closed()
      ..opened()
      ..closed();

    expect(reports, 2);
  });
}
