// Where a signed-in user belongs, given the backend's `user_state` /
// `next_step` value and whether an invite is still waiting to be redeemed.
//
// Kept free of page imports so the router, the splash, the login flow and the
// app-lifecycle watcher can all share one answer instead of each re-deriving
// onboarding routing.

/// The completion form. In invite mode it saves the profile *and* redeems the
/// token in one submit.
const completeProfileLocation = '/complete-profile';

/// The invite gate — redeems a token for a user who already has a complete
/// profile, then routes onward.
const inviteProcessingLocation = '/invite-processing';

/// Maps the backend `user_state` / `next_step` value to the route a signed-in
/// user should land on. Shared by the splash (session restore) and login flows
/// so onboarding routing stays consistent.
///
/// [hasPendingInvite] reports whether an invite token was captured from a deep
/// link and is still waiting to be redeemed.
String locationForAuthStep(String? step, {bool hasPendingInvite = false}) {
  // A pending invite outranks the user's own onboarding step: they followed an
  // invite link. Superadmins are exempt — they don't belong to a bank sampah and
  // have no invite to accept.
  if (hasPendingInvite && step != 'superadmin_dashboard') {
    // A brand-new joiner whose profile isn't complete yet finishes it and
    // redeems the token together on the completion screen (invite mode).
    if (step == 'complete_profile') return completeProfileLocation;
    // Everyone else already has a complete profile — sending them to the
    // completion form would trap them ("Profil sudah lengkap"). Hand off to the
    // invite gate instead: it redeems the token (joining a bank if the account
    // has none) or, if the account already belongs to a bank, bounces to the
    // dashboard with an explanatory notice. See [InviteGatePage].
    //
    // `dashboard` reaches here too, and deliberately: an already-signed-in user
    // who taps an invite link is sitting on their dashboard, and leaving them
    // there is exactly how the link used to be swallowed without ever calling
    // `POST /invites/accept`.
    return inviteProcessingLocation;
  }
  switch (step) {
    case 'superadmin_dashboard':
      return '/superadmin-dashboard';
    case 'complete_profile':
      return completeProfileLocation;
    case 'register_bank_sampah':
      return '/register-bank-sampah';
    case 'approval_pending':
      return '/pending-approval';
    case 'registration_rejected':
      // A rejected registration re-uses the registration form (in
      // re-application mode) so the user can fix their data and resubmit,
      // rather than being stranded on the pending screen.
      return '/register-bank-sampah';
    case 'dashboard':
    default:
      // `dashboard`, plus null/empty/unknown, land on the main dashboard.
      return '/dashboard';
  }
}

/// The screen that can actually redeem a pending invite for a user sitting at
/// onboarding [step], or `null` when this session has no way to redeem one.
///
/// Only two screens spend a token: the completion form (invite mode) and the
/// invite gate. Any other destination means this account can never redeem it —
/// today that is only a superadmin, who belongs to no bank sampah — and forcing
/// a redirect there would pin the user to one screen for the rest of the
/// session, since nothing would ever clear the token.
///
/// Callers that want to *interrupt* the user for a pending invite (the router's
/// top-level redirect, the resume watcher) should use this rather than
/// [locationForAuthStep], which always has to answer with somewhere to go.
String? pendingInviteLocation(String? step) {
  final location = locationForAuthStep(step, hasPendingInvite: true);
  return location == completeProfileLocation ||
          location == inviteProcessingLocation
      ? location
      : null;
}
