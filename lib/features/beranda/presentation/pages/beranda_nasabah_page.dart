import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';
import 'package:pilah_mobile/services/di.dart';

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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
            title: const Text('PILAH'),
            backgroundColor: const Color(0xFFF8FAFC),
            actions: []),
        body: SafeArea(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    const Text('Beranda',
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Selamat datang, ${widget.name}'),
                    TextButton(
                        onPressed: () => _select(null),
                        child: const Text('Pilih ulang bank sampah')),
                    NasabahResource<NasabahHome>(
                      key: ValueKey(_selectionVersion),
                      load: () =>
                          widget.repository.home(membershipId: _membershipId),
                      onSelect: _select,
                      builder: (context, home) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BalanceCard(
                              balance: home.balance,
                              onOpen: () => _details(
                                  'Saldo',
                                  NasabahResource<NasabahBalance>(
                                      load: () => widget.repository
                                          .balance(home.membershipId),
                                      builder: (_, balance) => Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(children: [
                                            Text(nasabahRupiah(balance.amount),
                                                style: const TextStyle(
                                                    fontSize: 28,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(balance.updatedAt == null
                                                ? 'Belum ada perubahan saldo.'
                                                : 'Diperbarui ${nasabahDate(balance.updatedAt!)}'),
                                          ])))),
                            ),
                            const SizedBox(height: 20),
                            _BankUnitCard(
                              unitName: home.bank.name,
                              onOpen: () => _details(
                                  'Detail Bank Sampah',
                                  NasabahResource<NasabahBank>(
                                      load: () => widget.repository
                                          .bank(home.membershipId),
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
                                          ])))),
                            ),
                            const SizedBox(height: 20),
                            const Text('Aktivitas Terbaru',
                                style: TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600)),
                            NasabahActivityList(activities: home.activities),
                            OutlinedButton(
                                onPressed: () => _details(
                                    'Riwayat Aktivitas',
                                    _History(
                                        repository: widget.repository,
                                        membershipId: home.membershipId)),
                                child: const Text('Riwayat Aktivitas')),
                          ]),
                    ),
                  ]),
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

const _emerald = Color(0xFF059669);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);
TextStyle _text(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = _ink,
  double height = 1.45,
}) =>
    TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

Widget _card({required Widget child}) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onOpen});
  final NasabahBalance balance;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: Color(0xFFD1FAE5),
                ),
                const SizedBox(width: 8),
                Text(
                  'SALDO TABUNGAN',
                  style: _text(
                    11,
                    weight: FontWeight.w600,
                    color: const Color(0xFFD1FAE5),
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
                    balance.updatedAt == null
                        ? 'Belum ada perubahan saldo'
                        : 'Diperbarui ${nasabahDate(balance.updatedAt!)}',
                    style: _text(
                      13,
                      color: const Color(0xFFD1FAE5),
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
  const _BankUnitCard({required this.unitName, required this.onOpen});
  final String unitName;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: _emerald,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BANK SAMPAH UNIT',
                    style: _text(
                      11,
                      weight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              unitName,
              style: _text(17, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: onOpen,
                child: Text(
                  'Detail Bank Sampah',
                  style: _text(
                    13,
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
