import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';
import 'package:pilah_mobile/services/di.dart';

final analyticsClientProvider =
    Provider<AnalyticsClient>((ref) => di<AnalyticsClient>());

final analyticsConsentStoreProvider =
    Provider<AnalyticsConsentStore>((ref) => di<AnalyticsConsentStore>());

/// Whether the signed-in user is a pengurus, the only people who may be
/// recorded. Nasabah and signed-out users never are.
final analyticsEligibleProvider = Provider<bool>((ref) {
  final auth = ref.watch(authenticationProvider);
  final role = auth is Authenticated ? auth.authEntity.role : null;
  return RoleDestinations.isStaff(role);
});

/// Whether to ask for consent now: a pengurus who has not chosen yet, on a
/// platform where recording is possible. Anyone who answered is not asked
/// again, and nobody is told they are recorded when nothing records.
final analyticsNeedsPromptProvider = Provider<bool>((ref) {
  final eligible = ref.watch(analyticsEligibleProvider);
  final available = ref.watch(analyticsClientProvider).isAvailable;
  final choice = ref.watch(analyticsConsentProvider).value;
  return eligible && available && choice == ConsentChoice.unset;
});

/// The user's recording choice, and the only place that starts or stops the
/// analytics client.
final analyticsConsentProvider =
    AsyncNotifierProvider<AnalyticsConsentController, ConsentChoice>(
        AnalyticsConsentController.new);

class AnalyticsConsentController extends AsyncNotifier<ConsentChoice> {
  @override
  Future<ConsentChoice> build() async {
    final eligible = ref.watch(analyticsEligibleProvider);
    final client = ref.read(analyticsClientProvider);
    final choice = await ref.read(analyticsConsentStoreProvider).read();
    if (!eligible) {
      // Whoever is signed in now may not be recorded, and the page may still
      // be recording the pengurus who just left.
      await client.stop();
    } else if (choice == ConsentChoice.granted) {
      await client.start();
    }
    return choice;
  }

  /// The pengurus agreed: remember it, then start recording.
  Future<void> grant() async {
    await ref.read(analyticsConsentStoreProvider).grant();
    await ref.read(analyticsClientProvider).start();
    state = const AsyncData(ConsentChoice.granted);
  }

  /// The pengurus declined: remember it and record nothing.
  Future<void> deny() async {
    await ref.read(analyticsConsentStoreProvider).deny();
    state = const AsyncData(ConsentChoice.denied);
  }

  /// The pengurus withdrew an earlier agreement. Recording stops first, so a
  /// failure to save the choice can never leave them recorded.
  Future<void> revoke() async {
    await ref.read(analyticsClientProvider).stop();
    await ref.read(analyticsConsentStoreProvider).deny();
    state = const AsyncData(ConsentChoice.denied);
  }
}
