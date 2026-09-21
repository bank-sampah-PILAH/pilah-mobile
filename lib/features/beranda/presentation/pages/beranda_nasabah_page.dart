import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

const _emerald = Color(0xFF059669);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);

/// Customer home; unavailable personal data is never replaced with bank totals.
class BerandaNasabahPage extends StatelessWidget {
  const BerandaNasabahPage({super.key});

  @override
  Widget build(
    BuildContext context,
  ) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          final ready = auth?.role == 'nasabah' &&
              auth?.nextStep == 'dashboard' &&
              auth?.bankSampahStatus == 'active';
          final bankName = auth?.bankSampahNama?.trim();
          final unitName = bankName == null || bankName.isEmpty
              ? 'Nama bank sampah belum tersedia'
              : bankName;
          final name = auth?.name.trim() ?? '';
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _BerandaHeader(name: name),
                      const SizedBox(height: 24),
                      Text('Beranda', style: _text(13, color: _muted)),
                      const SizedBox(height: 4),
                      if (!ready)
                        Text(
                          'Beranda tersedia setelah keanggotaan aktif.',
                          style: _text(15),
                        )
                      else ...[
                        Text(
                          'Selamat datang, $name',
                          style:
                              _text(20, weight: FontWeight.w700, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Langkah kecil Anda, dampak besar bagi lingkungan.',
                          style: _text(13, color: _muted),
                        ),
                        const SizedBox(height: 20),
                        _BalanceCard(
                            onOpen: () => _openDetails(
                                  context,
                                  'Saldo',
                                  'Informasi saldo Anda belum tersedia.',
                                )),
                        const SizedBox(height: 20),
                        _BankUnitCard(
                            unitName: unitName,
                            onOpen: () => _openDetails(
                                  context,
                                  'Detail Bank Sampah',
                                  'Unit bank sampah Anda: $unitName',
                                )),
                        const SizedBox(height: 20),
                        Text(
                          'Aktivitas Terbaru',
                          style: _text(17, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _ActivityCard(
                            onOpen: () => _openDetails(
                                  context,
                                  'Riwayat Aktivitas',
                                  'Informasi riwayat aktivitas Anda belum tersedia.',
                                )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

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

void _openDetails(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _text(20, weight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(message, style: _text(15, color: _muted)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: _text(15, weight: FontWeight.w600, color: _emerald),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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

class _BerandaHeader extends StatelessWidget {
  const _BerandaHeader({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: _emerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text('PILAH', style: _text(17, weight: FontWeight.w800)),
          const Spacer(),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFD1FAE5),
            child: Text(
              name.isEmpty ? 'N' : name.characters.first.toUpperCase(),
              style: _text(
                15,
                weight: FontWeight.w700,
                color: const Color(0xFF047857),
              ),
            ),
          ),
        ],
      );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onOpen});
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
              'Rp —',
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
                    'Saldo belum tersedia',
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.onOpen});
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => _card(
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 28,
              color: _muted,
            ),
            const SizedBox(height: 8),
            Text(
              'Aktivitas belum tersedia',
              style: _text(15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Informasi setoran dan aktivitas Anda akan tampil di sini.',
              textAlign: TextAlign.center,
              style: _text(13, color: _muted),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onOpen,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Riwayat Aktivitas',
                style: _text(
                  13,
                  weight: FontWeight.w600,
                  color: _emerald,
                ),
              ),
            ),
          ],
        ),
      );
}
