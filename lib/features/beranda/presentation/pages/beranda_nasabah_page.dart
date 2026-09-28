import 'package:pilah_mobile/core/bases/widgets/app_refresh_indicator.dart';
import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_bank_detail.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/services/di.dart';
import 'package:go_router/go_router.dart';

/// Membership eligibility comes from the API, not the login bank status.
class BerandaNasabahPage extends StatelessWidget {
  const BerandaNasabahPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          if (state is! Authenticated || state.authEntity.role != 'nasabah') {
            return const Scaffold(
                body: Center(child: Text('Silakan masuk sebagai nasabah.')));
          }
          final auth = state.authEntity;
          return _HomeSession(
              key: ObjectKey(auth),
              repository: di<NasabahRepository>(),
              name: auth.name);
        },
      );
}

class _HomeSession extends StatefulWidget {
  const _HomeSession({super.key, required this.repository, required this.name});
  final NasabahRepository repository;
  final String name;
  @override
  State<_HomeSession> createState() => _HomeSessionState();
}

class _HomeSessionState extends State<_HomeSession> {
  String? _membershipId;
  int _selectionVersion = 0;
  Future<void> Function()? _reload;
  Future<void> Function()? _reloadSchedule;

  Future<void> _refresh() async {
    await Future.wait([
      _reload?.call() ?? Future<void>.value(),
      _reloadSchedule?.call() ?? Future<void>.value(),
    ]);
  }

  void _select(String? id) => setState(() {
        _membershipId = id;
        _selectionVersion++;
      });

  void _details(String title, Widget body) {
    final initial = context.read<AuthenticationBloc>().state;
    final owner = initial is Authenticated ? initial.authEntity : null;
    final guardedBody = BlocBuilder<AuthenticationBloc, AuthenticationStates>(
      builder: (context, current) {
        if (current is! Authenticated ||
            current.authEntity.id != owner?.id ||
            current.authEntity.email != owner?.email ||
            current.authEntity.token != owner?.token ||
            current.authEntity.role != 'nasabah') {
          return const Text('Sesi berubah. Tutup detail dan masuk kembali.');
        }
        return body;
      },
    );
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => SafeArea(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                guardedBody,
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup')),
              ]),
            )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NasabahStyle.background,
        body: SafeArea(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: AppRefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _HomeHeader(
                          name: widget.name,
                          onOpenProfile: () => context.go(AppLocations.profile),
                        ),
                        const SizedBox(height: 12),
                        Text('Beranda', style: _text(12, color: _muted)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.push(
                              ApprovalBankSampahListPage.route,
                            ),
                            icon:
                                const Icon(Icons.fact_check_outlined, size: 16),
                            label: Text(
                              'Lihat Status Approval Bank Sampah',
                              style: _text(12,
                                  weight: FontWeight.w600, color: _emerald),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: _emerald,
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        NasabahResource<NasabahHome>(
                          key: ValueKey(_selectionVersion),
                          load: () => widget.repository.home(
                            membershipId: _membershipId,
                          ),
                          onSelect: _select,
                          registerReload: (reload) => _reload = reload,
                          builder: (context, home) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _BankUnitCard(
                                unitName: home.bank.name,
                                onSelect: () => _select(null),
                                onOpen: () => _details(
                                  'Detail Bank Sampah',
                                  NasabahResource<NasabahBank>(
                                    load: () => widget.repository
                                        .bank(home.membershipId),
                                    builder: (_, bank) => Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: NasabahBankDetail(bank: bank),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BalanceCard(
                                balance: home.balance,
                                bankName: home.bank.name,
                                latestActivity: home.activities.isEmpty
                                    ? null
                                    : home.activities.first,
                                onOpen: () => context.push(Uri(
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
                                load: _loadNearestSchedule,
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
                                    borderRadius: BorderRadius.circular(16),
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
                                                overflow: TextOverflow.ellipsis,
                                                style: _text(14,
                                                    weight: FontWeight.w600),
                                              ),
                                              Text(
                                                '${nasabahDate(start)} · ${_scheduleTime(start)}',
                                                style: _text(12, color: _muted),
                                              ),
                                              if (schedule.lokasi.isNotEmpty)
                                                Text(
                                                  schedule.lokasi,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      _text(12, color: _muted),
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
                                onAll: () => context.push(Uri(
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
                      ],
                    ),
                  ),
                ))),
      );
}

Future<JadwalEntity?> _loadNearestSchedule() async {
  final repository = di<JadwalRepository>();
  final now = DateTime.now();
  JadwalEntity? nearest;
  var pageNumber = 1;
  // ponytail: scans every upcoming page; add a server-side nearest query if
  // volume hurts homepage load time.
  while (true) {
    final result = await repository.getJadwal(page: pageNumber);
    final page = result.fold(
      (failure) => throw NasabahApiException(failure.displayMessage),
      (page) => page,
    );
    for (final schedule in page.items) {
      final start = schedule.mulaiPada.toLocal();
      if (schedule.isPublished &&
          !start.isBefore(now) &&
          (nearest == null || start.isBefore(nearest.mulaiPada.toLocal()))) {
        nearest = schedule;
      }
    }
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
  FontWeight weight = FontWeight.w400,
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
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
                          weight: FontWeight.w600,
                          color: NasabahStyle.emeraldLight,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0x22FFFFFF),
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
                    weight: FontWeight.w700,
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

class _BankUnitCard extends StatelessWidget {
  const _BankUnitCard({
    required this.unitName,
    required this.onOpen,
    required this.onSelect,
  });
  final String unitName;
  final VoidCallback onOpen;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: NasabahStyle.emeraldLight,
                  child: Text(
                    'BS',
                    style: _text(
                      11,
                      weight: FontWeight.w600,
                      color: _emerald,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KEANGGOTAAN AKTIF',
                          style: _text(10,
                              weight: FontWeight.w500, color: _muted)),
                      Text(
                        unitName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(14, weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pilih ulang bank sampah',
                  onPressed: onSelect,
                  icon: const Icon(Icons.expand_more),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: onOpen,
                child: Text(
                  'Detail Bank Sampah',
                  style: _text(
                    12,
                    weight: FontWeight.w600,
                    color: _emerald,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.onOpenProfile});
  final String name;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: _text(12, color: _muted)),
                Text(
                  name.isEmpty ? 'Nasabah' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(18, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Profil',
            onPressed: onOpenProfile,
            icon: CircleAvatar(
              radius: 19,
              backgroundColor: NasabahStyle.emeraldLight,
              child: Text(
                name.isEmpty ? 'N' : name.characters.first.toUpperCase(),
                style: _text(14,
                    weight: FontWeight.w600, color: NasabahStyle.emeraldDark),
              ),
            ),
          ),
        ],
      );
}

String _greeting() {
  final hour = DateTime.now().hour;
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
              child: Text(title, style: _text(17, weight: FontWeight.w600))),
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
