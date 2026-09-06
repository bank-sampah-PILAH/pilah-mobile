import 'package:flutter_test/flutter_test.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/core/router/pending_invite.dart';
import 'package:pilah_mobile/services/di.dart';

void main() {
  setUp(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
    di.registerSingleton<InviteTokenStore>(InviteTokenStore());
  });

  tearDown(() {
    if (di.isRegistered<InviteTokenStore>()) {
      di.unregister<InviteTokenStore>();
    }
  });

  group('InviteTokenStore change notification', () {
    test('announces a token arriving and a token being spent', () {
      final store = di<InviteTokenStore>();
      var notifications = 0;
      store.addListener(() => notifications++);

      store.save('invite-token-abc');
      expect(notifications, 1,
          reason: 'a screen already on top has no other way to learn the app '
              'just entered invite mode');

      store.clear();
      expect(notifications, 2);
    });

    test('stays quiet when nothing actually changed', () {
      final store = di<InviteTokenStore>()..save('invite-token-abc');
      var notifications = 0;
      store.addListener(() => notifications++);

      store.save('invite-token-abc');
      store.save('   ');
      expect(notifications, 0);

      store.clear();
      store.clear();
      expect(notifications, 1);
    });
  });

  group('resolvePendingInvite', () {
    test('is null with no token banked', () {
      expect(
          resolvePendingInvite(step: 'dashboard', role: 'pengelola'), isNull);
    });

    test('points a pengelola at the screen that can redeem the token', () {
      di<InviteTokenStore>().save('invite-token-abc');

      expect(
        resolvePendingInvite(step: 'dashboard', role: 'pengelola'),
        '/invite-processing',
      );
      expect(
        resolvePendingInvite(step: 'complete_profile', role: 'pengelola'),
        '/complete-profile',
      );
      expect(
        di<InviteTokenStore>().hasToken,
        isTrue,
        reason: 'the token is only spent by the screen that redeems it',
      );
    });

    test('discards a token a superadmin session can never spend', () {
      di<InviteTokenStore>().save('invite-token-abc');

      expect(
        resolvePendingInvite(step: 'superadmin_dashboard', role: 'superadmin'),
        isNull,
      );
      expect(
        di<InviteTokenStore>().hasToken,
        isFalse,
        reason:
            'a token now survives logout, so one left banked by a superadmin '
            'would follow the next pengelola signed in on this device',
      );
    });

    test('the superadmin role wins even if the step says otherwise', () {
      di<InviteTokenStore>().save('invite-token-abc');

      expect(
          resolvePendingInvite(step: 'dashboard', role: 'superadmin'), isNull);
      expect(di<InviteTokenStore>().hasToken, isFalse);
    });
  });
}
