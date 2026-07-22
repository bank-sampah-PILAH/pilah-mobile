import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/core/router/auth_routing.dart';
import 'package:pilah_mobile/core/router/invite_token_store.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/refresh_user_events.dart';
import 'package:pilah_mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:pilah_mobile/features/onboarding/domain/entities/invite_acceptance.dart';
import 'package:pilah_mobile/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:pilah_mobile/features/onboarding/presentation/widgets/invite_acceptance_notice.dart';
import 'package:pilah_mobile/services/di.dart';

/// Redeems a pending invite token for a user who already has a session and a
/// complete profile, then routes onward. Reached via [pendingInviteLocation]
/// when there is a pending invite and the user's step is not
/// `complete_profile` (that case fills the profile and joins on the completion
/// screen instead) — including the warm-start case, where an already-signed-in
/// user taps an invite link while sitting on their dashboard.
///
/// It covers every post-session invite branch:
///  1. Account is already on THIS bank sampah — as a member (HTTP 200,
///     `outcome: already_member`) or as its primary pengelola (HTTP 400,
///     "pengelola utama…") → dashboard + "sudah terdaftar" notice.
///  2. Account already belongs to a *different* bank sampah (one account = one
///     bank) → their own onboarding destination + error notice.
///  3. Account has no bank yet → the token is redeemed (join) and they land on
///     the dashboard.
///  4. The link or the call itself failed → the user's normal destination, with
///     the backend's own wording.
///
/// Which branch applies is decided by the `POST /invites/accept` response, the
/// only authority available: there is no invite-preview endpoint, so the app
/// cannot compare the invite's target bank against the user's own bank locally.
/// See [classifyInviteAcceptance] for how the two response shapes are read.
class InviteGatePage extends StatefulWidget {
  const InviteGatePage({super.key});

  static const route = '/invite-processing';

  @override
  State<InviteGatePage> createState() => _InviteGatePageState();
}

class _InviteGatePageState extends State<InviteGatePage> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    // Defer to the first frame so a redirect via context.go is safe.
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    if (_handled) return;
    _handled = true;

    final store = di<InviteTokenStore>();
    final token = store.token ?? '';

    final authState = context.read<AuthenticationBloc>().state;
    final user = authState is Authenticated ? authState.authEntity : null;
    final step = user?.nextStep;

    // No token to redeem (e.g. a manual navigation) — fall back to the user's
    // normal onboarding destination.
    if (token.isEmpty) {
      context.go(locationForAuthStep(step));
      return;
    }

    final (:result, :error) =
        await context.read<OnboardingCubit>().acceptInvite(token);
    if (!mounted) return;

    // Always, whatever came back. Redeemed, refused or unreachable, this gate
    // is the end of the token's life: it is what the routing priority keys off,
    // so a token left banked here would bounce every later navigation straight
    // back into this page — a spinner with nothing left to do. A user who needs
    // to retry can tap the link again.
    store.clear();

    final acceptance =
        classifyInviteAcceptance(result: result, error: error);

    if (acceptance == InviteAcceptance.joined) {
      // Refresh the cached user so the dashboard reflects the new association.
      context.read<AuthenticationBloc>().add(RefreshUserRequested());
    }

    // Navigate first, then notify: the toast is a pushed route, and raising it
    // before `go` replaces the stack tears it down with this page.
    switch (acceptance) {
      case InviteAcceptance.joined:
      case InviteAcceptance.alreadyMember:
        // Both put the user on the *inviting* bank sampah, and the backend only
        // hands out invites for one that is already active, so the dashboard is
        // always reachable here. Only the notice differs.
        context.go(DashboardPage.route);
        break;
      case InviteAcceptance.otherBank:
      case InviteAcceptance.rejected:
      case InviteAcceptance.failed:
        // The invite changed nothing about this account, so its own onboarding
        // step is the answer. That matters most for `otherBank`: the bank
        // sampah they already belong to may still be pending or rejected, and
        // sending them to a dashboard that 403s behind `IsActivePengelola`
        // would turn "you're already a pengelola" into a broken screen.
        context.go(locationForAuthStep(step));
        break;
    }

    showInviteAcceptanceNotice(
      acceptance,
      backendMessage: error?.displayMessage ?? '',
      // Read from the session as it stood before the call: a refused invite
      // changes nothing server-side, so the cached entity is still accurate.
      registrationUnderReview: hasRegistrationUnderReview(
        step: step,
        bankSampahStatus: user?.bankSampahStatus,
      ),
      // From the accept response, which serialises the bank just joined — the
      // cached entity still predates the join, and the refresh above is async.
      bankSampahNama: result?.bankSampahNama,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.greenDark),
      ),
    );
  }
}
