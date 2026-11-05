import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/widgets/analytics_recording_root.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/fake_analytics_client.dart';
import '../../../../support/fake_app_storage.dart';

/// Puts a frame around the app once it has started, as the real recorder does.
class _FramingClient extends FakeAnalyticsClient {
  _FramingClient() : super(recordsScreen: true);

  var started = false;

  @override
  Future<void> start() async {
    started = true;
    return super.start();
  }

  @override
  Widget wrapApp(Widget app) =>
      started ? Container(key: const ValueKey('recorder'), child: app) : app;
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var taps = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => taps++),
        child: Text('taps $taps'),
      );
}

void main() {
  testWidgets('the recorder appears around the app without rebuilding it', (
    tester,
  ) async {
    final storage = FakeAppStorage();
    final client = _FramingClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticationProvider.overrideWith(
            () => TestAuthenticationNotifier(
              initialState: Authenticated(
                authEntity: AuthEntity(
                  id: 'u1',
                  name: 'Tester',
                  email: 'tester@example.com',
                  photoUrl: '',
                  token: 'token',
                  role: 'pengelola',
                ),
              ),
            ),
          ),
          analyticsClientProvider.overrideWithValue(client),
          analyticsConsentStoreProvider
              .overrideWithValue(AnalyticsConsentStore(storage)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnalyticsRecordingRoot(child: _Counter())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('taps 0'));
    await tester.pump();
    expect(find.byKey(const ValueKey('recorder')), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AnalyticsRecordingRoot)),
    );
    await container.read(analyticsConsentProvider.notifier).grant();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recorder')), findsOneWidget);
    // The same screen state moved into the recorder.
    expect(find.text('taps 1'), findsOneWidget);
  });
}
