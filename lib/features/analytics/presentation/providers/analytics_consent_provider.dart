import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';
import 'package:pilah_mobile/services/di.dart';

/// The client for this build. Where none is registered (a test, or a build
/// without analytics) it is the no-op one, so the app behaves as if analytics
/// is off instead of failing, and nobody is ever recorded by accident.
final analyticsClientProvider = Provider<AnalyticsClient>((ref) =>
    di.isRegistered<AnalyticsClient>()
        ? di<AnalyticsClient>()
        : NoopAnalyticsClient());

/// Where choices are kept. Like the client, it does not insist on being
/// registered: without it the store is built over the same storage the module
/// would have used.
final analyticsConsentStoreProvider = Provider<AnalyticsConsentStore>((ref) =>
    di.isRegistered<AnalyticsConsentStore>()
        ? di<AnalyticsConsentStore>()
        : AnalyticsConsentStore(
            di<AppStorage>(instanceName: 'shared_preferences')));

/// Who is signed in, as the id a choice is kept under. Empty when nobody is,
/// or when the account has no id.
final analyticsUserIdProvider = Provider<String>(
  (ref) {
    final auth = ref.watch(authenticationProvider);
    return auth is Authenticated ? auth.authEntity.id ?? '' : '';
  },
  dependencies: [authenticationProvider],
);

/// Whether the signed-in user is a pengurus, the only people who may be
/// recorded. Nasabah and signed-out users never are.
final analyticsEligibleProvider = Provider<bool>(
  (ref) {
    final auth = ref.watch(authenticationProvider);
    final role = auth is Authenticated ? auth.authEntity.role : null;
    return RoleDestinations.isStaff(role);
  },
  dependencies: [authenticationProvider],
);

/// Whether the "Perekaman sesi" switch applies: to a pengurus, on a platform
/// that can record, whatever they chose before.
final analyticsToggleVisibleProvider = Provider<bool>(
  (ref) =>
      ref.watch(analyticsEligibleProvider) &&
      ref.watch(analyticsClientProvider).isAvailable,
  dependencies: [analyticsEligibleProvider, analyticsClientProvider],
);

/// Whether to ask for consent now: a pengurus who has not chosen yet, on a
/// platform where recording is possible. Anyone who answered is not asked
/// again, and nobody is told they are recorded when nothing records.
final analyticsNeedsPromptProvider = Provider<bool>(
  (ref) {
    // Cheapest checks first: the saved choice is only read when it can matter.
    if (!ref.watch(analyticsEligibleProvider)) return false;
    if (!ref.watch(analyticsClientProvider).isAvailable) return false;
    return ref.watch(analyticsConsentProvider).value == ConsentChoice.unset;
  },
  dependencies: [
    analyticsEligibleProvider,
    analyticsClientProvider,
    analyticsConsentProvider,
  ],
);

/// The user's recording choice, and the only place that starts or stops the
/// analytics client.
final analyticsConsentProvider =
    AsyncNotifierProvider<AnalyticsConsentController, ConsentChoice>(
  AnalyticsConsentController.new,
  dependencies: [
    analyticsEligibleProvider,
    analyticsUserIdProvider,
    analyticsClientProvider,
    analyticsConsentStoreProvider,
  ],
);

class AnalyticsConsentController extends AsyncNotifier<ConsentChoice> {
  /// Whose analytics the client is running for, or null when it is not.
  String? _recordingFor;

  @override
  Future<ConsentChoice> build() async {
    final eligible = ref.watch(analyticsEligibleProvider);
    final userId = ref.watch(analyticsUserIdProvider);
    final client = ref.read(analyticsClientProvider);
    final choice = await ref.read(analyticsConsentStoreProvider).read(userId);
    if (!eligible) {
      // Whoever is signed in now may not be recorded, and the page may still
      // be recording the pengurus who just left.
      await client.stop();
      _recordingFor = null;
    } else if (choice == ConsentChoice.granted) {
      await client.start();
      _recordingFor = userId;
    } else if (_recordingFor != null) {
      // Another pengurus took over, and has not agreed: the one before them
      // must not keep being recorded on their behalf.
      await client.stop();
      _recordingFor = null;
    }
    return choice;
  }

  /// The pengurus agreed: remember it, then start recording.
  Future<void> grant() async {
    final userId = ref.read(analyticsUserIdProvider);
    await ref.read(analyticsConsentStoreProvider).grant(userId);
    await ref.read(analyticsClientProvider).start();
    _recordingFor = userId;
    state = const AsyncData(ConsentChoice.granted);
  }

  /// The pengurus declined: remember it and record nothing.
  Future<void> deny() async {
    await ref
        .read(analyticsConsentStoreProvider)
        .deny(ref.read(analyticsUserIdProvider));
    state = const AsyncData(ConsentChoice.denied);
  }

  /// The pengurus withdrew an earlier agreement. Recording stops first, so a
  /// failure to save the choice can never leave them recorded.
  Future<void> revoke() async {
    await ref.read(analyticsClientProvider).stop();
    _recordingFor = null;
    await ref
        .read(analyticsConsentStoreProvider)
        .deny(ref.read(analyticsUserIdProvider));
    state = const AsyncData(ConsentChoice.denied);
  }
}
