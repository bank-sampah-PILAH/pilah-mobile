import 'package:firebase_core/firebase_core.dart';

bool firebaseWebConfigured(Map<String, String> environment) =>
    environment['FIREBASE_WEB_APP_ID']?.isNotEmpty ?? false;

Future<void> initializeFirebaseForEnvironment(
  Map<String, String> environment, {
  required bool isWeb,
}) async {
  final options = isWeb
      ? FirebaseOptions(
          apiKey: environment['FIREBASE_WEB_API_KEY'] ?? '',
          appId: environment['FIREBASE_WEB_APP_ID'] ?? '',
          messagingSenderId: environment['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          projectId: environment['FIREBASE_PROJECT_ID'] ?? '',
        )
      : null;
  await Firebase.initializeApp(options: options);
}
