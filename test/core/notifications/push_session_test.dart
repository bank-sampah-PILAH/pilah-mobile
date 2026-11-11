import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/notifications/push_session.dart';

void main() {
  test('registers a token and removes it when the session ends', () async {
    final calls = <String>[];
    final session = PushSession(
      getToken: () async => 'device-token',
      register: (token) async => calls.add('register:$token'),
      remove: (token) async => calls.add('remove:$token'),
      tokenRefresh: const Stream.empty(),
    );
    await session.start();
    await session.stop();
    expect(calls, ['register:device-token', 'remove:device-token']);
  });
  test('sign out waits for registration before removing the token', () async {
    final pending = Completer<void>();
    final registering = Completer<void>();
    final calls = <String>[];
    final session = PushSession(
      getToken: () async => 'device-token',
      register: (token) async {
        registering.complete();
        await pending.future;
        calls.add('register:$token');
      },
      remove: (token) async => calls.add('remove:$token'),
      tokenRefresh: const Stream.empty(),
    );
    final start = session.start();
    await registering.future;
    final stop = session.stop();
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
    pending.complete();
    await Future.wait([start, stop]);
    expect(calls, ['register:device-token', 'remove:device-token']);
  });
  test('replaces the previous token after Firebase refreshes it', () async {
    final refresh = StreamController<String>();
    final calls = <String>[];
    final session = PushSession(
      getToken: () async => 'old',
      register: (token) async => calls.add('register:$token'),
      remove: (token) async => calls.add('remove:$token'),
      tokenRefresh: refresh.stream,
    );
    await session.start();
    refresh.add('new');
    await Future<void>.delayed(Duration.zero);
    await session.stop();
    expect(calls, ['register:old', 'register:new', 'remove:old', 'remove:new']);
    await refresh.close();
  });
  test('invalidates the local token when server removal fails', () async {
    var invalidated = false;
    final session = PushSession(
      getToken: () async => 'old',
      register: (_) async {},
      remove: (_) async => throw StateError('offline'),
      invalidate: () async => invalidated = true,
      tokenRefresh: const Stream.empty(),
    );
    await session.start();
    await expectLater(session.stop(), throwsStateError);
    expect(invalidated, isTrue);
  });
  test('retries a transient registration failure during the session', () async {
    var attempts = 0;
    final delays = <Duration>[];
    final session = PushSession(
      getToken: () async => 'device-token',
      register: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('offline');
      },
      remove: (_) async {},
      tokenRefresh: const Stream.empty(),
      retryDelay: (delay) async => delays.add(delay),
    );
    await session.start();
    expect(attempts, 2);
    expect(delays, [const Duration(seconds: 2)]);
    await session.stop();
  });
}
