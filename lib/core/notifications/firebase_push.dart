import 'dart:async';

import 'package:pilah_mobile/core/notifications/web_push_open.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/notifications/notifications_page.dart';
import 'package:pilah_mobile/core/notifications/push_presentation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/core/notifications/push_session.dart';

String _currentPlatform({bool isWeb = kIsWeb}) {
  if (isWeb) return 'web';
  if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
  return 'android';
}

void requestNotificationPermissionAfterFirstFrame({bool isWeb = kIsWeb}) {
  if (isWeb || Firebase.apps.isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(FirebaseMessaging.instance
        .requestPermission()
        .then<void>((_) {}, onError: (_) {}));
  });
}

PushSession createPushSession(NetworkService network, {bool isWeb = kIsWeb}) {
  FirebaseMessaging messaging() => FirebaseMessaging.instance;
  const path = '/api/v1/device-tokens/';
  return PushSession(
    getToken: () async {
      if (Firebase.apps.isEmpty) return null;
      if (isWeb) await messaging().requestPermission();
      return messaging().getToken(
          vapidKey: isWeb ? dotenv.env['FIREBASE_WEB_VAPID_KEY'] : null);
    },
    invalidate: () async {
      if (Firebase.apps.isNotEmpty) await messaging().deleteToken();
    },
    tokenRefresh: Firebase.apps.isEmpty
        ? const Stream.empty()
        : messaging().onTokenRefresh,
    register: (token) async {
      await network.post(path, data: {
        'token': token,
        'platform': _currentPlatform(isWeb: isWeb),
      });
    },
    remove: (token) async => network.delete(path, data: {'token': token}),
  );
}

PushPresentation<RemoteMessage>? createPushPresentation({bool isWeb = kIsWeb}) {
  if (Firebase.apps.isEmpty) return null;
  void openHistory() {
    AppNotification.afterNavigation(
        (context) => NotificationsPage.open(context));
  }

  return PushPresentation<RemoteMessage>(
    foreground: FirebaseMessaging.onMessage,
    opened:
        isWeb ? webPushOpens : FirebaseMessaging.onMessageOpenedApp.map((_) {}),
    initialOpen: () async => isWeb
        ? takeWebPushOpen()
        : await FirebaseMessaging.instance.getInitialMessage() != null,
    open: openHistory,
    show: (message) {
      final notification = message.notification;
      if (notification == null) return;
      AppNotification.afterNavigation((context) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
          content: Text([notification.title, notification.body]
              .whereType<String>()
              .join('\n')),
          action: SnackBarAction(label: 'Lihat', onPressed: openHistory),
        ));
      });
    },
  );
}
