import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_nasabah_page.dart';
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _HomeHeader(
                        name: widget.name,
                        onOpenProfile: () => context.go(AppLocations.profile),
                      ),
                      const SizedBox(height: 12),
                      Text('Beranda', style: _text(12, color: _muted)),
                      const SizedBox(height: 16),
                      NasabahResource<NasabahHome>(
                        key: ValueKey(_selectionVersion),
                        load: () => widget.repository.home(
                          membershipId: _membershipId,
                        ),
                        onSelect: _select,
                        builder: (context, home) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BankUnitCard(
                              unitName: home.bank.name,
                              onSelect: () => _select(null),
                              onOpen: () => _details(
                                'Detail Bank Sampah',
                                NasabahResource<NasabahBank>(
                                  load: () =>
                                      widget.repository.bank(home.membershipId),
                                  builder: (_, bank) => Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(children: [
                                      Text(bank.name),
                                      Text(bank.address.isEmpty
                                          ? 'Alamat belum tersedia'
                                          : bank.address),
                                      Text(bank.city),
                                      Text(bank.phone.isEmpty
                                          ? 'Kontak belum tersedia'
                                          : bank.phone),
                                    ]),
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
                              onOpen: () => _details(
                                'Saldo',
                                NasabahResource<NasabahBalance>(
                                  load: () => widget.repository
                                      .balance(home.membershipId),
                                  builder: (_, balance) => Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(children: [
                                      Text(nasabahRupiah(balance.amount),
                                          style: _text(
                                            28,
                                            weight: FontWeight.w700,
                                          )),
                                      Text(balance.updatedAt == null
                                          ? 'Belum ada perubahan saldo.'
                                          : 'Diperbarui ${nasabahDate(balance.updatedAt!)}'),
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _details(
                                      'Riwayat Aktivitas',
                                      _History(
                                        repository: widget.repository,
                                        membershipId: home.membershipId,
                                      ),
                                    ),
                                    icon: const Icon(Icons.history),
                                    label: const Text('Riwayat Aktivitas'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _emerald,
                                      minimumSize: const Size.fromHeight(48),
                                      side: const BorderSide(
                                          color: NasabahStyle.line),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => context.push(
                                      RiwayatPencairanNasabahPage.route,
                                    ),
                                    icon: const Icon(Icons.south_west),
                                    label: const Text('Pencairan'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _emerald,
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _SectionHeading(
                              title: 'Jadwal Terdekat',
                              onAll: () => context.go(JadwalPage.route),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.go(JadwalPage.route),
                              child: _card(
                                child: Row(children: [
                                  const Icon(Icons.calendar_month_outlined,
                                      color: _emerald),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Lihat jadwal kegiatan bank sampah Anda.',
                                      style: _text(13, color: _muted),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: _muted),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SectionHeading(
                              title: 'Terbaru',
                              onAll: () => _details(
                                'Riwayat Aktivitas',
                                _History(
                                  repository: widget.repository,
                                  membershipId: home.membershipId,
                                ),
                              ),
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
                ))),
      );
}

class _History extends StatefulWidget {
  const _History({required this.repository, required this.membershipId});
  final NasabahRepository repository;
  final String membershipId;
  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  int _page = 1;
  @override
  Widget build(BuildContext context) => Column(children: [
        NasabahResource<NasabahHistory>(
            key: ValueKey(_page),
            load: () =>
                widget.repository.history(widget.membershipId, page: _page),
            builder: (_, history) => Column(children: [
                  NasabahActivityList(activities: history.activities),
                  if (history.hasNext)
                    TextButton(
                        onPressed: () => setState(() => _page++),
                        child: const Text('Berikutnya')),
                ])),
        Text('Halaman $_page'),
        if (_page > 1)
          TextButton(
              onPressed: () => setState(() => _page--),
              child: const Text('Sebelumnya')),
      ]);
}

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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _emerald,
          borderRadius: BorderRadius.circular(16),
        ),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    latestActivity == null
                        ? balance.updatedAt == null
                            ? 'Saldo tabungan saat ini'
                            : 'Diperbarui ${nasabahDate(balance.updatedAt!)}'
                        : '${_activityTitle(latestActivity!.type)} · ${nasabahDate(latestActivity!.date)}',
                    style: _text(
                      12,
                      color: NasabahStyle.emeraldLight,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0x22000000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onOpen,
                  child: Text(
                    'Saldo',
                    style: _text(
                      13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
