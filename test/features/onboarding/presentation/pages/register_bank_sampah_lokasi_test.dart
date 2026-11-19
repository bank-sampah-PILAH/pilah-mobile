import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/onboarding/presentation/pages/register_bank_sampah_screen.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/onboarding_support.dart';
import '../../../../support/pump_app.dart';
import '../../../../support/stub_api.dart';

/// PIL-326 optional coordinate section on bank registration: open the picker,
/// keep the picked point, remove it again.
void main() {
  late StubApi api;
  late ProviderContainer onboarding;
  late TestAuthenticationNotifier auth;

  setUp(() {
    api = StubApi();
    onboarding = buildOnboardingContainer(buildOnboardingDataSource(api));
    auth = authNotifierIn(AuthenticationInitial());
  });

  tearDown(() => onboarding.dispose());

  Future<void> open(WidgetTester tester) async {
    await pumpRouted(
      tester,
      UncontrolledProviderScope(
        container: onboarding,
        child: withAuthenticationProvider(
          auth,
          RegisterBankSampahScreen(
            // No tiles are fetched inside `flutter test`.
            tileLayerBuilder: () => const SizedBox.shrink(),
          ),
        ),
      ),
      size: const Size(800, 2600),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a picked point shows its coordinates and can be removed',
      (tester) async {
    await open(tester);

    expect(find.text('Pilih di peta'), findsOneWidget);

    await tester.tap(find.text('Pilih di peta'));
    await tester.pumpAndSettle();
    expect(find.text('Simpan Lokasi'), findsOneWidget);

    await tester.tap(find.text('Simpan Lokasi'));
    await tester.pumpAndSettle();

    // The picker returns the coordinate pair; registration shows it and offers
    // a way to drop it again.
    expect(find.text('Pilih di peta'), findsNothing);
    expect(find.textContaining(','), findsWidgets);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Pilih di peta'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
