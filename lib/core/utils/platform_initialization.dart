/// Platform policy separated from the plugin/process entrypoints.
Future<void> initializePlatformServices({
  required bool isWeb,
  required String? oauthClientId,
  required Future<void> Function() initializeFirebase,
  required Future<void> Function({String? clientId, String? serverClientId})
      initializeGoogle,
}) async {
  if (!isWeb) await initializeFirebase();
  await initializeGoogle(
    clientId: isWeb ? oauthClientId : null,
    serverClientId: isWeb ? null : oauthClientId,
  );
}
