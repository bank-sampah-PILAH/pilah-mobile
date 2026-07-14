/// Maps the backend `user_state` / `next_step` value to the route a signed-in
/// user should land on. Shared by the splash (session restore) and login flows
/// so onboarding routing stays consistent.
///
/// [hasPendingInvite] reports whether an invite token was captured from a deep
/// link and is still waiting to be redeemed.
String locationForAuthStep(String? step, {bool hasPendingInvite = false}) {
  // A pending invite outranks the user's own onboarding step: they followed an
  // invite link, so send them to the join screen, which completes their profile
  // and redeems the token together. Superadmins are exempt — they don't belong
  // to a bank sampah and have no invite to accept.
  if (hasPendingInvite && step != 'superadmin_dashboard') {
    return '/complete-profile';
  }
  switch (step) {
    case 'superadmin_dashboard':
      return '/superadmin-dashboard';
    case 'complete_profile':
      return '/complete-profile';
    case 'register_bank_sampah':
      return '/register-bank-sampah';
    case 'approval_pending':
      return '/pending-approval';
    case 'registration_rejected':
      // No dedicated rejected screen yet; the pending screen shows the status.
      return '/pending-approval';
    case 'dashboard':
    default:
      // `dashboard`, plus null/empty/unknown, land on the main dashboard.
      return '/dashboard';
  }
}
