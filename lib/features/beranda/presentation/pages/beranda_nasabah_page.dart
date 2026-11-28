import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'dart:async';

import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/notifications/notifications_page.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/active_membership_scope.dart';
import 'package:pilah_mobile/features/authentication/presentation/states/authentication_states.dart';
import 'package:pilah_mobile/features/authentication/presentation/providers/authentication_provider.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/widgets/bank_membership_panel.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_page_result.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/font_weight.dart';

/// Membership eligibility comes from the API, not the login bank status.
class BerandaNasabahPage extends ConsumerWidget {
  const BerandaNasabahPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authenticationProvider);
    if (state is! Authenticated || state.authEntity.role != 'nasabah') {
      return const Scaffold(
          body: Center(child: Text('Silakan masuk sebagai nasabah.')));
    }
    final auth = state.authEntity;
    return _HomeSession(
      key: ObjectKey(auth),
      repository: di<NasabahRepository>(),
      name: auth.name,
    );
  }
}

class _HomeSession extends ConsumerStatefulWidget {
  const _HomeSession({
    super.key,
    required this.repository,
    required this.name,
  });
  final NasabahRepository repository;
  final String name;
  @override
  ConsumerState<_HomeSession> createState() => _HomeSessionState();
}

class _HomeSessionState extends ConsumerState<_HomeSession>
    with WidgetsBindingObserver {
  Future<void> Function()? _reload;
  Future<void> Function()? _reloadSchedule;

  Future<void> _refresh() async {
    await Future.wait([
      _reload?.call() ?? Future<void>.value(),
      _reloadSchedule?.call() ?? Future<void>.value(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh().catchError((_) {}));
    }
  }

  Widget _notifications(BuildContext context) => AppTapTarget(
        label: 'Notifikasi',
        onTap: () => NotificationsPage.open(context),
        child: const Icon(Icons.notifications_outlined),
      );

  // The web shell's rail replaces the phone app bar: the page paints its own
  // title and the rail already leads to Profil. A narrow browser has no rail,
  // so it keeps the app bar.
  bool get _webHeader => WebContentSurface.contains(context);

  /// The phone app bar, with the avatar that leads to Profil. Null on the web
  /// shell, where the rail carries both and the page paints its own title.
  PreferredSizeWidget? _appBar(BuildContext context) => _webHeader
      ? null
      : NasabahPageAppBar(
          title: 'Beranda',
          actions: [
            _notifications(context),
            IconButton(
              tooltip: 'Profil',
              onPressed: () => context.go(AppLocations.profile),
              icon: CircleAvatar(
                radius: 19,
                backgroundColor: NasabahStyle.emeraldLight,
                child: Text(
                  widget.name.isEmpty
                      ? 'N'
                      : widget.name.characters.first.toUpperCase(),
                  style: _text(14,
                      weight: AppFontWeight.semibold,
                      color: NasabahStyle.emeraldDark),
                ),
              ),
            ),
          ],
        );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WebContentSurface.pageColor(context,
            phone: NasabahStyle.background),
        appBar: _appBar(context),
        body: SafeArea(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
                  child: AppRefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: _webHeader
                          ? const EdgeInsets.fromLTRB(
                              AppSpacing.webGutter,
                              AppSpacing.webTop,
                              AppSpacing.webGutter,
                              AppSpacing.xl)
                          : const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        if (_webHeader) ...[
                          AppPageHeader(
                            title: 'Beranda',
                            actions: [_notifications(context)],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        _HomeGreeting(name: widget.name),
                        const SizedBox(height: AppSpacing.md),
                        ActiveMembershipScope(
                          builder: (context, membership) =>
                              NasabahResource<NasabahHome>(
                            load: () => widget.repository.home(
                              membershipId: membership.id,
                            ),
                            onSelect: membership.select,
                            registerReload: (reload) => _reload = reload,
                            builder: (context, home) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                BankMembershipHomeCard(
                                  activeBankName: home.bank.name,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _BalanceCard(
                                  balance: home.balance,
                                  bankName: home.bank.name,
                                  latestActivity: home.activities.isEmpty
                                      ? null
                                      : home.activities.first,
                                  onOpen: () => context.go(Uri(
                                    path: AppLocations.history,
                                    queryParameters: {
                                      'keanggotaan_id': home.membershipId,
                                    },
                                  ).toString()),
                                ),
                                const SizedBox(height: 24),
                                _SectionHeading(
                                  title: 'Jadwal Terdekat',
                                  onAll: () => context.go(JadwalPage.route),
                                ),
                                const SizedBox(height: 8),
                                NasabahResource<JadwalEntity?>(
                                  load: () =>
                                      _loadNearestSchedule(home.membershipId),
                                  registerReload: (reload) =>
                                      _reloadSchedule = reload,
                                  builder: (context, schedule) {
                                    if (schedule == null) {
                                      return _card(
                                        child: Row(children: [
                                          const Icon(
                                            Icons.calendar_month_outlined,
                                            color: _emerald,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Belum ada jadwal mendatang.',
                                              style: _text(13, color: _muted),
                                            ),
                                          ),
                                        ]),
                                      );
                                    }
                                    final start = schedule.mulaiPada.toLocal();
                                    return InkWell(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.lg),
                                      onTap: () => context.go(Uri(
                                        path: JadwalPage.route,
                                        queryParameters: {
                                          'date': _scheduleDateParam(start),
                                        },
                                      ).toString()),
                                      child: _card(
                                        child: Row(children: [
                                          const Icon(
                                            Icons.calendar_month_outlined,
                                            color: _emerald,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  schedule.jenisKegiatan,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _text(14,
                                                      weight: AppFontWeight
                                                          .semibold),
                                                ),
                                                Text(
                                                  '${nasabahDate(start)} · ${_scheduleTime(start)}',
                                                  style:
                                                      _text(12, color: _muted),
                                                ),
                                                if (schedule.lokasi.isNotEmpty)
                                                  Text(
                                                    schedule.lokasi,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: _text(12,
                                                        color: _muted),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right,
                                              color: _muted),
                                        ]),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                _SectionHeading(
                                  title: 'Terbaru',
                                  onAll: () => context.go(Uri(
                                    path: AppLocations.history,
                                    queryParameters: {
                                      'keanggotaan_id': home.membershipId,
                                    },
                                  ).toString()),
                                ),
                                const SizedBox(height: 8),
                                NasabahActivityList(
                                  activities: home.activities.take(1).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ))),
      );
}

/// One page of [membershipId]'s schedules, or null when the bank is refused.
///
/// A bank that is no longer this nasabah's to read is not an error worth
/// repeating here: the bank card above already carries the refusal, so the
/// schedule card simply has nothing to show.
Future<JadwalPageResult?> _schedulePage(int pageNumber, String membershipId) {
  final result = di<JadwalRepository>()
      .getJadwal(page: pageNumber, membershipId: membershipId);
  return result.then((either) => either.fold<JadwalPageResult?>(
        (failure) => failure.response?.statusCode == 403
            ? null
            : throw NasabahApiException(failure.displayMessage),
        (page) => page,
      ));
}

/// The earlier of [nearest] and the soonest published schedule in [items] that
/// has not finished yet.
JadwalEntity? _soonestOf(
  Iterable<JadwalEntity> items,
  JadwalEntity? nearest,
  DateTime now,
) {
  var soonest = nearest;
  for (final schedule in items) {
    final start = schedule.mulaiPada.toLocal();
    if (schedule.isPublished &&
        !schedule.selesaiPada.toLocal().isBefore(now) &&
        (soonest == null || start.isBefore(soonest.mulaiPada.toLocal()))) {
      soonest = schedule;
    }
  }
  return soonest;
}

/// The nearest upcoming schedule of [membershipId], or null when there is
/// none.
///
/// The bank is explicit because the backend otherwise refuses the list for a
/// nasabah with more than one (PIL-235); before that it merged the schedules
/// of every bank they belonged to, and this card showed whichever came first.
Future<JadwalEntity?> _loadNearestSchedule(String membershipId) async {
  final now = clock.now();
  JadwalEntity? nearest;
  var pageNumber = 1;
  // ponytail: scans every upcoming page; add a server-side nearest query if
  // volume hurts homepage load time.
  while (true) {
    final page = await _schedulePage(pageNumber, membershipId);
    if (page == null) return null;
    nearest = _soonestOf(page.items, nearest, now);
    if (page.items.isEmpty || !page.hasMore) return nearest;
    pageNumber++;
  }
}

String _scheduleDateParam(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _scheduleTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}.'
    '${date.minute.toString().padLeft(2, '0')}';

const _emerald = NasabahStyle.emerald;
const _ink = NasabahStyle.ink;
const _muted = NasabahStyle.muted;
TextStyle _text(
  double size, {
  FontWeight weight = AppFontWeight.regular,
  Color color = _ink,
  double height = 1.45,
}) =>
    NasabahStyle.text(size,
        weight: weight, color: color, height: height, tabularFigures: true);

Widget _card({required Widget child}) =>
    NasabahCard(raised: true, child: child);

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.bankName,
    required this.latestActivity,
    required this.onOpen,
  });
  final NasabahBalance balance;
  final String bankName;
  final NasabahActivity? latestActivity;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Material(
        color: _emerald,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SALDO DI ${bankName.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(
                          11,
                          weight: AppFontWeight.semibold,
                          color: NasabahStyle.emeraldLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: NasabahStyle.emeraldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nasabahRupiah(balance.amount),
                  style: _text(
                    28,
                    weight: AppFontWeight.bold,
                    color: Colors.white,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latestActivity == null
                      ? balance.updatedAt == null
                          ? 'Saldo tabungan saat ini'
                          : 'Diperbarui ${nasabahDate(balance.updatedAt!)}'
                      : '${_activityTitle(latestActivity!.type)} · ${nasabahDate(latestActivity!.date)}',
                  style: _text(12, color: NasabahStyle.emeraldLight),
                ),
              ],
            ),
          ),
        ),
      );
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greeting(), style: _text(12, color: _muted)),
          Text(
            name.isEmpty ? 'Nasabah' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(18, weight: AppFontWeight.semibold),
          ),
        ],
      );
}

String _greeting() {
  final hour = clock.now().hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.onAll});
  final String title;
  final VoidCallback? onAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(title,
                  style: _text(17, weight: AppFontWeight.semibold))),
          if (onAll != null)
            TextButton(onPressed: onAll, child: const Text('Semua')),
        ],
      );
}

String _activityTitle(String type) => switch (type.toLowerCase()) {
      'setoran' => 'Setoran',
      'pencairan' => 'Pencairan',
      _ => type,
    };
