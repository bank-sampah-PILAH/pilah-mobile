/// Maps the backend `user_state` / `next_step` value to the route a signed-in
/// user should land on. Shared by the splash (session restore) and login flows
/// so onboarding routing stays consistent.
String locationForAuthStep(String? step) {
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
