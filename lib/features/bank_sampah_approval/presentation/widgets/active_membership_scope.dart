import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/providers/active_membership_provider.dart';

/// The bank the screens inside one [ActiveMembershipScope] read, and the
/// handle that changes it.
class ActiveMembership {
  const ActiveMembership({required this.id, required this.select});

  /// The membership to send as `keanggotaan_id`, or null when none could be
  /// resolved here.
  ///
  /// Null is not an error. The screen asks without a membership and lets the
  /// API answer, which is the one bank a single-bank nasabah has, the picker
  /// (422 with `pilihan`) for a nasabah with several and nothing saved, or 403
  /// when there is nothing they may open.
  final String? id;

  /// Shows [id] and remembers it as the active bank, so every other Nasabah
  /// screen opens on the same one.
  ///
  /// A null id asks for the picker back. There is no bank to remember then, so
  /// that choice lives on this screen alone, as does one the storage refused
  /// to keep; both are given up as soon as the active bank changes anywhere,
  /// because that is an explicit choice too.
  final Future<void> Function(String? id) select;
}

/// Resolves the bank a Nasabah screen should show, once, and keeps it in step
/// with the rest of the app.
///
/// Saldo, riwayat, jadwal and pengumuman all read one bank at a time and must
/// read the *same* one (PIL-235). Each of them resolving it for itself is how
/// the beranda and "Bank sampah saya" came to disagree, so the lifecycle lives
/// here instead: seed from the saved choice, follow a switch made elsewhere,
/// and persist a pick made inside.
///
/// The subtree is keyed on the resolved bank, so a screen that loads in
/// `initState` reloads for the new bank without having to watch for the change
/// itself.
class ActiveMembershipScope extends ConsumerStatefulWidget {
  const ActiveMembershipScope({
    super.key,
    this.membershipId,
    required this.builder,
  });

  /// A bank named by the route (`keanggotaan_id`), which wins over the saved
  /// choice for as long as the screen is open: a link that says which bank to
  /// show is a choice of its own, and following the active bank away from it
  /// would throw away what the link asked for.
  final String? membershipId;

  final Widget Function(BuildContext, ActiveMembership) builder;

  @override
  ConsumerState<ActiveMembershipScope> createState() =>
      _ActiveMembershipScopeState();
}

class _ActiveMembershipScopeState extends ConsumerState<ActiveMembershipScope> {
  /// The bank this scope is showing, and the one the active selection last
  /// resolved to. They differ only while a pick of the screen's own is on
  /// display: "none", to get the picker back, or a pick the storage would not
  /// keep.
  String? _shownId;
  String? _activeId;

  /// Whether the first resolution is still in flight, so the value it reports
  /// is recorded rather than treated as a switch.
  var _seeding = false;
  var _resolved = false;

  /// Whether this scope is already listening for a switch made elsewhere. A
  /// route that names a bank does not listen, and starts to only if the link
  /// later stops naming one.
  var _following = false;

  /// Bumped on every change of bank, and used to key the subtree.
  var _version = 0;

  @override
  void initState() {
    super.initState();
    final named = widget.membershipId;
    if (named != null && named.isNotEmpty) {
      _shownId = named;
      _resolved = true;
      return;
    }
    _followActiveBank();
    unawaited(_seed());
  }

  /// Re-resolves when the route names a different bank.
  ///
  /// The screens that take a bank from the query sit in kept-alive shell
  /// branches, where going from `?keanggotaan_id=A` to `?keanggotaan_id=B`
  /// reuses this State instead of building a new one. Without this the screen
  /// would keep showing A while the link says B.
  @override
  void didUpdateWidget(covariant ActiveMembershipScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.membershipId == oldWidget.membershipId) return;
    final named = widget.membershipId;
    if (named != null && named.isNotEmpty) {
      setState(() {
        _shownId = named;
        _resolved = true;
        _version++;
      });
      return;
    }
    // The link stopped naming a bank, so the saved choice answers again.
    setState(() {
      _resolved = false;
      _version++;
    });
    if (!_following) _followActiveBank();
    unawaited(_seed());
  }

  /// Resolves the saved choice before the first build.
  ///
  /// Resolving here rather than letting the screens read it off their first
  /// frame is what keeps each of them to a single request: read too early the
  /// choice is still null, and a screen would fetch the default bank and then
  /// fetch the saved one.
  Future<void> _seed() async {
    _seeding = true;
    try {
      final resolved = await ref.read(activeMembershipProvider.future);
      _shownId = resolved;
      _activeId = resolved;
    } catch (_) {
      // The saved choice could not be read. None is the right answer: the
      // screen asks the API without a membership, which still works for a
      // nasabah with one bank and offers the picker to a nasabah with more.
    } finally {
      _seeding = false;
      if (mounted) setState(() => _resolved = true);
    }
  }

  /// Follows the active bank changing elsewhere: switched on the "Bank sampah
  /// saya" detail page, or resolved to another bank because a refresh of the
  /// membership list left the saved one unopenable.
  ///
  /// The comparison is against the bank this scope last resolved to, not
  /// against the previous state, so a later refresh is treated like any other
  /// change rather than skipped along with the first resolution. That first
  /// resolution is the one case with nothing to reload, because [_seed] is
  /// already awaiting the very value being reported.
  void _followActiveBank() {
    _following = true;
    ref.listenManual(activeMembershipProvider, (_, next) {
      if (next.isLoading) return;
      final resolved = next.value;
      if (resolved == _activeId) return;
      _activeId = resolved;
      if (_seeding) {
        _shownId = resolved;
        return;
      }
      setState(() {
        _shownId = resolved;
        _version++;
      });
    });
  }

  Future<void> _select(String? id) async {
    final kept = id != null &&
        await ref.read(activeMembershipProvider.notifier).select(id);
    if (!mounted) return;
    setState(() {
      _shownId = id;
      if (kept) _activeId = id;
      _version++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return KeyedSubtree(
      key: ValueKey(_version),
      child: widget.builder(
        context,
        ActiveMembership(id: _shownId, select: _select),
      ),
    );
  }
}
