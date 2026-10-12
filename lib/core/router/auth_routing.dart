// Where a signed-in user belongs, given the backend's `user_state` /
// `next_step` value and whether an invite is still waiting to be redeemed.
//
// Kept free of page imports so the router, the splash, the login flow and the
// app-lifecycle watcher can all share one answer instead of each re-deriving
// onboarding routing.

import 'package:pilah_mobile/core/router/app_locations.dart';

/// The completion form. In invite mode it saves the profile *and* redeems the
/// token in one submit.
const completeProfileLocation = '/complete-profile';

/// The invite gate — redeems a token for a user who already has a complete
/// profile, then routes onward.
const inviteProcessingLocation = '/invite-processing';

const _webSupportedRoles = {'superadmin', 'pengelola', 'pengelola_induk'};

bool isSupportedWebRole(String? role) => _webSupportedRoles.contains(role);

bool isRoleSupportedOnPlatform(String? role, {required bool isWeb}) =>
    !isWeb || isSupportedWebRole(role);

String? webRoleRedirect({
  required bool isWeb,
  required String path,
  required String loginPath,
  required String? role,
}) =>
    isWeb && path != loginPath && !isSupportedWebRole(role) ? loginPath : null;

/// Paths that make sense without a session, and so must not be bounced to the
/// splash. `/splash` is where the restore itself happens.
const _publicPaths = {
  '/splash',
  '/login',
  '/choose-role',
  '/forgot_password',
  '/invite',
};

/// Sends a cold start that landed straight on a protected path to the splash.
///
/// On web the browser URL decides the first route, so refreshing on
/// `/#/dashboard` skips the splash — the only place that restores the saved
/// session — and the shell renders signed out although the token is still in
/// storage. The splash restores it and routes the user back to [path], which
/// it receives as `from`.
String? sessionRestoreRedirect({
  required bool sessionChecked,
  required String path,
}) =>
    sessionChecked || _publicPaths.contains(path)
        ? null
        : '/splash?from=${Uri.encodeComponent(path)}';

/// Sends a signed-out user who reaches a protected path to the login page.
///
/// Logging out already navigates to login, but the browser's Back button can
/// return to `/dashboard` afterwards, where the shell has no role to render.
String? signedOutRedirect({required bool signedOut, required String path}) =>
    signedOut && !_publicPaths.contains(path) ? '/login' : null;

/// Where the splash sends a restored session. A fully onboarded user goes back
/// to [from], the page they refreshed on; anyone still mid-onboarding keeps
/// their [target] step.
String locationAfterRestore({required String target, String? from}) {
  final safe = from != null &&
      from.startsWith('/') &&
      !from.startsWith('//') &&
      !_publicPaths.contains(from);
  return safe && target == AppLocations.dashboard ? from : target;
}

/// Maps the backend `user_state` / `next_step` value to the route a signed-in
/// user should land on. Shared by the splash (session restore) and login flows
/// so onboarding routing stays consistent.
///
/// [hasPendingInvite] reports whether an invite token was captured from a deep
/// link and is still waiting to be redeemed. [role] gates invite routing to
/// the role accepted by the backend.
String locationForAuthStep(
  String? step, {
  bool hasPendingInvite = false,
  String? role,
}) {
  // A pending invite outranks the user's own onboarding step only for the
  // backend-supported role. Known excluded roles keep their route and discard
  // the token through [resolvePendingInvite].
  if (hasPendingInvite && role == 'pengelola') {
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
    case 'register_nasabah':
      return '/register-nasabah';
    case 'nasabah_dashboard':
      return AppLocations.dashboard;
    case 'register_bank_sampah_induk':
      return '/register-bank-sampah-induk';
    case 'pengelola_induk_dashboard':
      return '/pengelola-induk-dashboard';
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
      return AppLocations.dashboard;
  }
}

/// The screen that can redeem a pending invite for a user at onboarding
/// [step], or `null` when [role] cannot redeem one.
///
/// Only two screens spend a token: the completion form (invite mode) and the
/// invite gate. Only `pengelola` can use either screen for bank invites.
///
/// Callers that want to *interrupt* the user for a pending invite (the router's
/// top-level redirect, the resume watcher) should use this rather than
/// [locationForAuthStep], which always has to answer with somewhere to go.
String? pendingInviteLocation(String? step, {required String? role}) {
  if (role != 'pengelola') return null;

  final location = locationForAuthStep(
    step,
    hasPendingInvite: true,
    role: role,
  );
  return location == completeProfileLocation ||
          location == inviteProcessingLocation
      ? location
      : null;
}
