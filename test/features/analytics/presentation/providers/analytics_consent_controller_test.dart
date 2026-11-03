import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:pilah_mobile/core/analytics/analytics_client.dart';
import 'package:pilah_mobile/core/analytics/analytics_consent_store.dart';
import 'package:pilah_mobile/core/analytics/consent_revocation_channel.dart';
import 'package:pilah_mobile/core/analytics/analytics_screen_tracker.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_consent_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_client_provider.dart';
import 'package:pilah_mobile/features/analytics/presentation/providers/analytics_screen_tracker_provider.dart';
import 'package:pilah_mobile/features/authentication/domain/model/auth.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';

import '../../../../support/auth_support.dart';
import '../../../../support/fake_analytics_client.dart';
import '../../../../support/fake_app_storage.dart';

Authenticated _signedInAs(String role, {String? id = 'u1'}) => Authenticated(
      authEntity: AuthEntity(
        id: id,
        name: 'Tester',
        email: 'tester@example.com',
        photoUrl: '',
        token: 'token',
        role: role,
      ),
    );

void main() {
  late FakeAppStorage storage;
  late FakeAnalyticsClient client;
  late TestAuthenticationNotifier auth;
  late _FakeChannel channel;
  late _RecordingTracker tracker;

  setUp(() {
    tracker = _RecordingTracker();
    storage = FakeAppStorage();
    client = FakeAnalyticsClient();
    channel = _FakeChannel();
    auth = TestAuthenticationNotifier(initialState: _signedInAs('pengelola'));
  });

  ProviderContainer containerForTest() {
    final container = ProviderContainer(overrides: [
      authenticationProvider.overrideWith(() => auth),
      analyticsClientProvider.overrideWithValue(client),
      analyticsScreenTrackerProvider.overrideWithValue(tracker),
      analyticsConsentStoreProvider
          .overrideWithValue(AnalyticsConsentStore(storage)),
      consentRevocationChannelProvider.overrideWithValue(channel),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('a change of who is signed in while a choice is being saved or read',
      () {
    ProviderContainer containerWith(AnalyticsConsentStore store) {
      final container = ProviderContainer(overrides: [
        authenticationProvider.overrideWith(() => auth),
        analyticsClientProvider.overrideWithValue(client),
        analyticsConsentStoreProvider.overrideWithValue(store),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('does not start recording from a run that is out of date', () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final store = _GatedStore(storage)..gateNextRead();
      final container = containerWith(store);
      final first = container.read(analyticsConsentProvider.future);
      await Future<void>.delayed(Duration.zero);

      // The pengurus signs out of being one while the first read is pending.
      auth.setStateForTest(_signedInAs('nasabah'));
      await container.read(analyticsConsentProvider.future);
      store.release();
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(client.calls, isNot(contains('start')));
    });

    test('agreeing does not start recording once the user may not be recorded',
        () async {
      final store = _GatedStore(storage);
      final container = containerWith(store);
      await container.read(analyticsConsentProvider.future);
      store.gateNextGrant();

      final agreeing =
          container.read(analyticsConsentProvider.notifier).grant();
      await Future<void>.delayed(Duration.zero);
      auth.setStateForTest(_signedInAs('nasabah'));
      await Future<void>.delayed(Duration.zero);
      store.release();
      await agreeing;

      expect(client.calls, isNot(contains('start')));
    });

    test('agreeing still starts when nothing changed meanwhile', () async {
      final container = containerWith(_GatedStore(storage));
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).grant();

      expect(client.calls, contains('start'));
    });
  });

  test('nothing starts until the pengurus has chosen', () async {
    final container = containerForTest();

    final choice = await container.read(analyticsConsentProvider.future);

    expect(choice, ConsentChoice.unset);
    expect(client.calls, isEmpty);
  });

  test('a pengurus who agreed before is recorded again without being asked',
      () async {
    await AnalyticsConsentStore(storage).grant('u1');
    final container = containerForTest();

    final choice = await container.read(analyticsConsentProvider.future);

    expect(choice, ConsentChoice.granted);
    expect(client.calls, ['start']);
  });

  test('a nasabah is never recorded, even if the device remembers an agreement',
      () async {
    await AnalyticsConsentStore(storage).grant('u1');
    auth.setStateForTest(_signedInAs('nasabah'));
    final container = containerForTest();

    await container.read(analyticsConsentProvider.future);

    expect(client.calls, isNot(contains('start')));
  });

  test(
      'recording stops when the pengurus signs out and someone else takes over',
      () async {
    await AnalyticsConsentStore(storage).grant('u1');
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);
    expect(client.calls, ['start']);

    auth.setStateForTest(_signedInAs('nasabah'));
    await container.read(analyticsConsentProvider.future);

    expect(client.calls, ['start', 'stop']);
  });

  test('agreeing remembers the choice and starts recording', () async {
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);

    await container.read(analyticsConsentProvider.notifier).grant();

    expect(client.calls, ['start']);
    expect(
        await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.granted);
    expect(
        container.read(analyticsConsentProvider).value, ConsentChoice.granted);
  });

  group('asking for consent', () {
    Future<bool> needsPrompt(ProviderContainer container) async {
      await container.read(analyticsConsentProvider.future);
      return container.read(analyticsNeedsPromptProvider);
    }

    test('a pengurus who has not chosen is asked', () async {
      expect(await needsPrompt(containerForTest()), isTrue);
    });

    test('a nasabah is never asked', () async {
      auth.setStateForTest(_signedInAs('nasabah'));

      expect(await needsPrompt(containerForTest()), isFalse);
    });

    test('nobody is asked about a recorder that cannot record', () async {
      client = FakeAnalyticsClient(isAvailable: false);

      expect(await needsPrompt(containerForTest()), isFalse);
    });

    test('nobody is asked twice, whatever they answered', () async {
      for (final answer in [
        (AnalyticsConsentStore store) => store.grant('u1'),
        (AnalyticsConsentStore store) => store.deny('u1'),
      ]) {
        // A fresh app start each time: new storage, session and notifier.
        storage = FakeAppStorage();
        auth =
            TestAuthenticationNotifier(initialState: _signedInAs('pengelola'));
        await answer(AnalyticsConsentStore(storage));

        expect(await needsPrompt(containerForTest()), isFalse);
      }
    });
  });

  test('declining remembers the choice and never starts recording', () async {
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);

    await container.read(analyticsConsentProvider.notifier).deny();

    expect(client.calls, isEmpty);
    expect(
        await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.denied);
    expect(
        container.read(analyticsConsentProvider).value, ConsentChoice.denied);
  });

  test('withdrawing consent stops recording and remembers the refusal',
      () async {
    final container = containerForTest();
    await container.read(analyticsConsentProvider.future);
    await container.read(analyticsConsentProvider.notifier).grant();

    await container.read(analyticsConsentProvider.notifier).revoke();

    expect(client.calls, ['start', 'stop']);
    expect(
        await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.denied);
    expect(
        container.read(analyticsConsentProvider).value, ConsentChoice.denied);
  });

  group('withdrawing in another tab', () {
    test('withdrawing here tells the other tabs who withdrew', () async {
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      await container.read(analyticsConsentProvider.notifier).grant();

      await container.read(analyticsConsentProvider.notifier).revoke();

      expect(channel.announced, ['u1']);
    });

    test('stops recording the same pengurus when another tab withdrew',
        () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      expect(client.calls, ['start']);

      channel.fromOtherTab('u1');
      await Future<void>.delayed(Duration.zero);

      expect(client.calls, ['start', 'stop']);
      expect(
          container.read(analyticsConsentProvider).value, ConsentChoice.denied);
    });

    test('ignores a withdrawal by somebody else', () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      channel.fromOtherTab('u2');
      await Future<void>.delayed(Duration.zero);

      expect(client.calls, ['start']);
      expect(container.read(analyticsConsentProvider).value,
          ConsentChoice.granted);
    });
  });

  group('one device, more than one pengurus', () {
    test('a second pengurus is not recorded on the first one\'s agreement',
        () async {
      await AnalyticsConsentStore(storage).grant('u1');
      auth.setStateForTest(_signedInAs('pengelola', id: 'u2'));
      final container = containerForTest();

      final choice = await container.read(analyticsConsentProvider.future);

      expect(choice, ConsentChoice.unset);
      expect(client.calls, isEmpty);
    });

    test('a second pengurus is asked, even though the first one agreed',
        () async {
      await AnalyticsConsentStore(storage).grant('u1');
      auth.setStateForTest(_signedInAs('pengelola', id: 'u2'));
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      expect(container.read(analyticsNeedsPromptProvider), isTrue);
    });

    test('the first pengurus is still recorded when they come back', () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      auth.setStateForTest(_signedInAs('pengelola', id: 'u2'));
      await container.read(analyticsConsentProvider.future);
      auth.setStateForTest(_signedInAs('pengelola', id: 'u1'));
      final choice = await container.read(analyticsConsentProvider.future);

      expect(choice, ConsentChoice.granted);
      expect(client.calls, ['start', 'stop', 'start']);
    });

    test('recording stops when another pengurus takes over without signing out',
        () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      expect(client.calls, ['start']);

      auth.setStateForTest(_signedInAs('pengelola', id: 'u2'));
      await container.read(analyticsConsentProvider.future);

      expect(client.calls, ['start', 'stop']);
    });

    test('agreeing is remembered for that pengurus only', () async {
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).grant();

      final store = AnalyticsConsentStore(storage);
      expect(await store.read('u1'), ConsentChoice.granted);
      expect(await store.read('u2'), ConsentChoice.unset);
    });

    test('an account without an id records for now and remembers nothing',
        () async {
      auth.setStateForTest(_signedInAs('pengelola', id: null));
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).grant();

      expect(client.calls, ['start']);
      expect(
          await AnalyticsConsentStore(storage).read(''), ConsentChoice.unset);
    });
  });

  group('when analytics starts', () {
    test('it says the app was opened and where the user is', () async {
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).grant();

      expect(client.log, [
        'start',
        'identify:u1',
        'register',
        'capture:app_dibuka',
      ]);
      expect(tracker.reported, 1);
    });

    test('a pengurus who agreed before does the same on opening the app',
        () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();

      await container.read(analyticsConsentProvider.future);

      expect(client.log, [
        'start',
        'identify:u1',
        'register',
        'capture:app_dibuka',
      ]);
      expect(tracker.reported, 1);
    });

    test('nothing is announced when the pengurus declines or has not chosen',
        () async {
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).deny();

      expect(client.log, isEmpty);
      expect(tracker.reported, 0);
    });

    test('nothing is announced when the pengurus withdraws', () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      client.log.clear();

      await container.read(analyticsConsentProvider.notifier).revoke();

      // Nothing announced, and the user is forgotten.
      expect(client.log, ['stop', 'reset']);
    });
  });

  group('who the user is', () {
    test('analytics is told their id and role once they agree', () async {
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).grant();

      expect(client.identified, ['u1']);
      expect(client.registered, [
        {'peran': 'pengelola'},
      ]);
    });

    test('an id is never sent for someone who has not agreed', () async {
      final container = containerForTest();

      await container.read(analyticsConsentProvider.future);
      await container.read(analyticsConsentProvider.notifier).deny();

      expect(client.identified, isEmpty);
      expect(client.registered, isEmpty);
    });

    test('a nasabah is never identified', () async {
      await AnalyticsConsentStore(storage).grant('u1');
      auth.setStateForTest(_signedInAs('nasabah'));
      final container = containerForTest();

      await container.read(analyticsConsentProvider.future);

      expect(client.identified, isEmpty);
    });

    test('an account with no id is not identified, but its role still is',
        () async {
      // Without an id nothing can be remembered, so it agrees in this session.
      auth.setStateForTest(_signedInAs('pengelola', id: null));
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);

      await container.read(analyticsConsentProvider.notifier).grant();

      expect(client.identified, isEmpty);
      expect(client.registered, [
        {'peran': 'pengelola'},
      ]);
    });

    test('withdrawing forgets the user after stopping', () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      client.log.clear();

      await container.read(analyticsConsentProvider.notifier).revoke();

      expect(client.log, ['stop', 'reset']);
    });

    test('signing out forgets the user, so the next one is not tied to them',
        () async {
      await AnalyticsConsentStore(storage).grant('u1');
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      client.log.clear();

      auth.setStateForTest(Unauthenticated());
      await container.read(analyticsConsentProvider.future);

      expect(client.log, ['stop', 'reset']);
    });
  });

  group('only a pengurus can agree', () {
    test('a nasabah who reaches the switch is not recorded or identified',
        () async {
      auth.setStateForTest(_signedInAs('nasabah'));
      final container = containerForTest();
      await container.read(analyticsConsentProvider.future);
      client.calls.clear();

      await container.read(analyticsConsentProvider.notifier).grant();

      expect(client.calls, isEmpty);
      expect(client.identified, isEmpty);
      expect(client.registered, isEmpty);
      expect(
          await AnalyticsConsentStore(storage).read('u1'), ConsentChoice.unset);
    });
  });
}

/// A tracker that only counts how often it was asked to repeat the screen.
class _RecordingTracker implements AnalyticsScreenTracker {
  int reported = 0;

  @override
  void reportCurrent() => reported++;

  @override
  void attach() {}

  @override
  void dispose() {}

  @override
  AnalyticsClient get client => throw UnimplementedError();

  @override
  Listenable get changes => throw UnimplementedError();

  @override
  String? Function() get currentPath => throw UnimplementedError();
}

/// A store whose next read or grant waits until [release], so a test can change
/// who is signed in while one is still pending.
class _GatedStore extends AnalyticsConsentStore {
  _GatedStore(super.storage);

  Completer<void>? _gate;
  bool _readGated = false;
  bool _grantGated = false;

  void gateNextRead() {
    _gate = Completer<void>();
    _readGated = true;
  }

  void gateNextGrant() {
    _gate = Completer<void>();
    _grantGated = true;
  }

  void release() => _gate?.complete();

  @override
  Future<ConsentChoice> read(String userId) async {
    if (_readGated) {
      _readGated = false;
      await _gate!.future;
    }
    return super.read(userId);
  }

  @override
  Future<void> grant(String userId) async {
    if (_grantGated) {
      _grantGated = false;
      await _gate!.future;
    }
    return super.grant(userId);
  }
}

class _FakeChannel implements ConsentRevocationChannel {
  final announced = <String>[];
  final _incoming = StreamController<String>.broadcast();

  void fromOtherTab(String userId) => _incoming.add(userId);

  @override
  void announce(String userId) => announced.add(userId);

  @override
  Stream<String> get revoked => _incoming.stream;

  @override
  void close() => _incoming.close();
}
