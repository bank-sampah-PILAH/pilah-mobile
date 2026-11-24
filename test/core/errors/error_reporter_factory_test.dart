@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/errors/error_reporter.dart';
import 'package:pilah_mobile/core/errors/error_reporter_factory.dart';

void main() {
  test('off the web, nothing is reported until a platform provides a reporter',
      () {
    expect(createPlatformErrorReporter(), isA<NoopErrorReporter>());
  });
}
