import 'package:pilah_mobile/core/analytics/consent_revocation_channel.dart';

/// Outside the web the app has one window, so there is nobody to tell.
ConsentRevocationChannel createConsentRevocationChannel() =>
    const _SingleWindowChannel();

class _SingleWindowChannel implements ConsentRevocationChannel {
  const _SingleWindowChannel();

  @override
  void announce(String userId) {}

  @override
  Stream<String> get revoked => const Stream<String>.empty();

  @override
  void close() {}
}
