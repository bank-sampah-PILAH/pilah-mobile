import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/network_exception.dart';
import 'package:pilah_mobile/core/errors/error_message.dart';

void main() {
  group('ErrorMessage.of', () {
    test('uses the message of the error, cleaned', () {
      expect(
        ErrorMessage.of(StateError('gagal untuk budi@example.com')),
        'Bad state: gagal untuk [email]',
      );
    });

    test('names the type when the error has no message of its own', () {
      // An error that prints as "Instance of '<class>'" would show a shortened
      // class name in a release web build, which says nothing.
      expect(
        ErrorMessage.of(InternalServerErrorException()),
        'InternalServerErrorException',
      );
    });
  });
}
