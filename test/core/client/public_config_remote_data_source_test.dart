import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/client/public_config_remote_data_source.dart';

import '../../support/stub_api.dart';

void main() {
  test(
    'reads reviewer access from the uncached public config endpoint',
    () async {
      final api = StubApi();
      api.on('GET', '/api/public-config', json: {'demoLoginEnabled': true});

      final enabled = await PublicConfigRemoteDataSource(
        api.network,
      ).reviewerLoginEnabled();

      expect(enabled, isTrue);
      expect(api.last.path, '/api/public-config');
      expect(api.last.headers['Cache-Control'], 'no-store');
    },
  );

  test(
    'keeps reviewer access disabled when the strict flag is false',
    () async {
      final api = StubApi();
      api.on('GET', '/api/public-config', json: {'demoLoginEnabled': false});

      final enabled = await PublicConfigRemoteDataSource(
        api.network,
      ).reviewerLoginEnabled();

      expect(enabled, isFalse);
    },
  );

  test('rejects anything outside the single strict boolean contract', () async {
    for (final config in [
      {'demoLoginEnabled': 'true'},
      {'demoLoginEnabled': true, 'extra': 'value'},
    ]) {
      final api = StubApi();
      api.on('GET', '/api/public-config', json: config);

      await expectLater(
        PublicConfigRemoteDataSource(api.network).reviewerLoginEnabled(),
        throwsFormatException,
      );
    }
  });
}
