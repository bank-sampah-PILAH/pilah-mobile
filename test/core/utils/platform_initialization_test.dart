import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/utils/platform_initialization.dart';

void main() {
  for (final isWeb in [true, false]) {
    test('initializes platform services in order for isWeb=$isWeb', () async {
      final calls = <String>[];
      await initializePlatformServices(
        isWeb: isWeb,
        oauthClientId: 'oauth-client',
        initializeFirebase: () async => calls.add('firebase'),
        initializeGoogle: ({clientId, serverClientId}) async {
          calls.add('google');
          expect(clientId, isWeb ? 'oauth-client' : null);
          expect(serverClientId, isWeb ? null : 'oauth-client');
        },
      );
      expect(calls, isWeb ? ['google'] : ['firebase', 'google']);
    });
  }
  test('does not hide native Firebase failures or continue into OAuth',
      () async {
    var googleCalls = 0;
    final error = StateError('Firebase unavailable');
    await expectLater(
        initializePlatformServices(
          isWeb: false,
          oauthClientId: null,
          initializeFirebase: () async => throw error,
          initializeGoogle: ({clientId, serverClientId}) async => googleCalls++,
        ),
        throwsA(same(error)));
    expect(googleCalls, 0);
  });
}
