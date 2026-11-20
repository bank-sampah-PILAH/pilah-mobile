@TestOn('browser')
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart'
    as core;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart'
    as messaging;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/notifications/firebase_push.dart';
import 'package:pilah_mobile/core/notifications/web_push_open.dart';
import 'package:web/web.dart' as web;

class _FirebaseCore extends core.FirebasePlatform {
  final platformApp = core.FirebaseAppPlatform(
    core.defaultFirebaseAppName,
    const FirebaseOptions(
      apiKey: 'api-key',
      appId: 'app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
    ),
  );
  bool hasApp = false;

  @override
  List<core.FirebaseAppPlatform> get apps => hasApp ? [platformApp] : [];

  @override
  core.FirebaseAppPlatform app([String name = core.defaultFirebaseAppName]) =>
      platformApp;

  @override
  Future<core.FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async =>
      platformApp;
}

class _FirebaseMessaging extends messaging.FirebaseMessagingPlatform {
  final refresh = StreamController<String>.broadcast();
  final vapidKeys = <String?>[];
  bool tokenDeleted = false;

  @override
  messaging.FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) =>
      this;

  @override
  messaging.FirebaseMessagingPlatform setInitialValues(
          {bool? isAutoInitEnabled}) =>
      this;

  @override
  Future<messaging.NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async =>
      const messaging.NotificationSettings(
        alert: messaging.AppleNotificationSetting.enabled,
        announcement: messaging.AppleNotificationSetting.disabled,
        authorizationStatus: messaging.AuthorizationStatus.authorized,
        badge: messaging.AppleNotificationSetting.enabled,
        carPlay: messaging.AppleNotificationSetting.disabled,
        lockScreen: messaging.AppleNotificationSetting.enabled,
        notificationCenter: messaging.AppleNotificationSetting.enabled,
        showPreviews: messaging.AppleShowPreviewSetting.always,
        timeSensitive: messaging.AppleNotificationSetting.disabled,
        criticalAlert: messaging.AppleNotificationSetting.disabled,
        sound: messaging.AppleNotificationSetting.enabled,
        providesAppNotificationSettings:
            messaging.AppleNotificationSetting.disabled,
      );

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    vapidKeys.add(vapidKey);
    return 'web-device-token';
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<void> deleteToken() async {
    tokenDeleted = true;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;
}

class _MockNetworkService extends Mock implements NetworkService {}

final _firebaseCore = _FirebaseCore();
final _firebaseMessaging = _FirebaseMessaging();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late core.FirebasePlatform? previousFirebaseCore;
  late messaging.FirebaseMessagingPlatform previousFirebaseMessaging;

  setUpAll(() {
    previousFirebaseCore = Firebase.delegatePackingProperty;
    previousFirebaseMessaging = messaging.FirebaseMessagingPlatform.instance;
    Firebase.delegatePackingProperty = _firebaseCore;
    messaging.FirebaseMessagingPlatform.instance = _firebaseMessaging;
    dotenv.loadFromString(envString: 'FIREBASE_WEB_VAPID_KEY=web-vapid-key');
  });

  setUp(() {
    _firebaseCore.hasApp = true;
    _firebaseMessaging.vapidKeys.clear();
    _firebaseMessaging.tokenDeleted = false;
  });

  tearDownAll(() async {
    Firebase.delegatePackingProperty = previousFirebaseCore;
    messaging.FirebaseMessagingPlatform.instance = previousFirebaseMessaging;
    await _firebaseMessaging.refresh.close();
  });

  test('uses web push setup and consumes notification-open events', () async {
    final network = _MockNetworkService();
    when(() => network.post(
          '/api/v1/device-tokens/',
          data: {'token': 'web-device-token', 'platform': 'web'},
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/device-tokens/'),
        ));
    when(() => network.delete(
          '/api/v1/device-tokens/',
          data: {'token': 'web-device-token'},
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/device-tokens/'),
        ));

    final session = createPushSession(network);
    await session.start();
    await session.stop();
    expect(_firebaseMessaging.vapidKeys, ['web-vapid-key']);
    expect(_firebaseMessaging.tokenDeleted, isTrue);
    verify(() => network.post(
          '/api/v1/device-tokens/',
          data: {'token': 'web-device-token', 'platform': 'web'},
        )).called(1);

    final presentation = createPushPresentation()!;
    web.window.sessionStorage.setItem('pilah-notification-open', '1');
    expect(await presentation.initialOpen(), isTrue);
    expect(takeWebPushOpen(), isFalse);

    final opens = webPushOpens;
    final nextOpen = opens.first;
    web.window.sessionStorage.setItem('pilah-notification-open', '1');
    web.window.dispatchEvent(web.Event('pilah-notification-open'));
    await expectLater(nextOpen, completion(null));
    expect(takeWebPushOpen(), isFalse);
  });
}
