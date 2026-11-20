// Tells other open tabs of the same app that somebody withdrew their consent.
export 'consent_revocation_channel_stub.dart'
    if (dart.library.js_interop) 'consent_revocation_channel_web.dart';

/// How a withdrawal reaches the other places the same app is open, so none of
/// them keeps recording someone who has said stop.
abstract interface class ConsentRevocationChannel {
  /// Tell the other tabs that [userId] withdrew.
  void announce(String userId);

  /// The ids that withdrew in another tab. Never includes this tab's own.
  Stream<String> get revoked;

  void close();
}
