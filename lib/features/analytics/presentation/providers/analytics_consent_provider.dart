import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/core/analytics/consent_revocation_channel.dart';
import 'package:pilah_mobile/core/storage/app_storage.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/role_destinations.dart';
import 'package:pilah_mobile/services/di.dart';

/// Where choices are kept. Like the client, it does not insist on being
/// registered: without it the store is built over the same storage the module
/// would have used.
final analyticsConsentStoreProvider = Provider<AnalyticsConsentStore>((ref) =>
    di.isRegistered<AnalyticsConsentStore>()
        ? di<AnalyticsConsentStore>()
        : AnalyticsConsentStore(
            di<AppStorage>(instanceName: 'shared_preferences')));

/// How a withdrawal reaches the other tabs. Outside the web it tells nobody.
final consentRevocationChannelProvider = Provider<ConsentRevocationChannel>(
  (ref) {
    final channel = createConsentRevocationChannel();
    ref.onDispose(channel.close);
    return channel;
  },
);

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
    consentRevocationChannelProvider,
  ],
);

class AnalyticsConsentController extends AsyncNotifier<ConsentChoice> {
  /// Whose analytics the client is running for, or null when it is not.
  String? _recordingFor;

  StreamSubscription<String>? _otherTabs;

  /// Stops recording the signed-in user when another tab says they withdrew:
  /// a withdrawal has to end the recording everywhere, not only where the
  /// button was pressed.
  void _listenForWithdrawals() {
    _otherTabs ??= ref.read(consentRevocationChannelProvider).revoked.listen(
      (userId) async {
        if (userId.isEmpty || userId != ref.read(analyticsUserIdProvider)) {
          return;
        }
        await ref.read(analyticsClientProvider).stop();
        _recordingFor = null;
        state = const AsyncData(ConsentChoice.denied);
      },
    );
    ref.onDispose(() {
      _otherTabs?.cancel();
      _otherTabs = null;
    });
  }

  @override
  Future<ConsentChoice> build() async {
    _listenForWithdrawals();
    final eligible = ref.watch(analyticsEligibleProvider);
    final userId = ref.watch(analyticsUserIdProvider);
    final client = ref.read(analyticsClientProvider);
    final choice = await ref.read(analyticsConsentStoreProvider).read(userId);
    // Somebody signed in or out while the saved choice was being read: this
    // run knows an old answer, and the newer run is the one that decides.
    if (_changedSince(eligible, userId)) return choice;
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

  /// Whether who is signed in, or whether they may be recorded, is no longer
  /// what it was when [eligible] and [userId] were read.
  bool _changedSince(bool eligible, String userId) =>
      ref.read(analyticsEligibleProvider) != eligible ||
      ref.read(analyticsUserIdProvider) != userId;

  /// The pengurus agreed: remember it, then start recording.
  Future<void> grant() async {
    final eligible = ref.read(analyticsEligibleProvider);
    final userId = ref.read(analyticsUserIdProvider);
    await ref.read(analyticsConsentStoreProvider).grant(userId);
    // The choice is saved, but whoever is signed in now may not be recorded,
    // or may be somebody else: starting would record the wrong person.
    if (_changedSince(eligible, userId) || !eligible) return;
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
    final userId = ref.read(analyticsUserIdProvider);
    await ref.read(analyticsConsentStoreProvider).deny(userId);
    ref.read(consentRevocationChannelProvider).announce(userId);
    state = const AsyncData(ConsentChoice.denied);
  }
}
