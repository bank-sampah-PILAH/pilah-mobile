import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/pencairan/presentation/pages/riwayat_pencairan_nasabah_page.dart';

/// Customer home; unavailable personal data is never replaced with bank totals.
class BerandaNasabahPage extends StatelessWidget {
  const BerandaNasabahPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthenticationBloc, AuthenticationStates>(
        builder: (context, state) {
          final auth = state is Authenticated ? state.authEntity : null;
          final ready = auth?.role == 'nasabah' &&
              (auth?.nextStep == 'dashboard' ||
                  auth?.nextStep == 'nasabah_dashboard') &&
              auth?.bankSampahStatus == 'active';
          final bankName = auth?.bankSampahNama?.trim();
          final unitName = bankName == null || bankName.isEmpty
              ? 'Nama bank sampah belum tersedia'
              : bankName;
          final name = auth?.name.trim() ?? '';

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _HomeHeader(
                        name: name,
                        canOpenProfile: auth?.role == 'nasabah',
                      ),
                      const SizedBox(height: 12),
                      Text('Beranda',
                          style: _text(12, color: AppColors.grey100)),
                      const SizedBox(height: 20),
                      if (!ready)
                        _InfoCard(
                          icon: Icons.hourglass_top_rounded,
                          message:
                              'Beranda tersedia setelah keanggotaan aktif.',
                        )
                      else ...[
                        _MembershipCard(
                          name: unitName,
                          onOpen: () => _openDetails(
                            context,
                            'Detail Bank Sampah',
                            'Unit bank sampah Anda: $unitName',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BalanceCard(
                          onOpen: () => _openDetails(
                            context,
                            'Saldo',
                            'Informasi saldo Anda belum tersedia.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(
                                  RiwayatPencairanNasabahPage.route,
                                ),
                                icon: const Icon(Icons.history),
                                label: const Text('Riwayat Pencairan'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.greenDark,
                                  minimumSize: const Size.fromHeight(48),
                                  side: const BorderSide(
                                    color: AppColors.grey200,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => context.go(JadwalPage.route),
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text('Jadwal'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.greenDark,
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
                          child: const _InfoCard(
                            icon: Icons.calendar_month_outlined,
                            message: 'Lihat jadwal kegiatan bank sampah Anda.',
                            trailing: Icons.chevron_right,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _SectionHeading(title: 'Terbaru'),
                        const SizedBox(height: 8),
                        _ActivityCard(
                          onOpen: () => _openDetails(
                            context,
                            'Riwayat Aktivitas',
                            'Informasi riwayat aktivitas Anda belum tersedia.',
                          ),
                        ),
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
  Color color = AppColors.black,
}) =>
    AppTextStyle.small.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.canOpenProfile});
  final String name;
  final bool canOpenProfile;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: _text(12, color: AppColors.grey100)),
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
            onPressed: canOpenProfile ? () => context.go('/profile') : null,
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.greenLight,
              child: Text(
                name.isEmpty ? 'N' : name.characters.first.toUpperCase(),
                style: _text(14,
                    weight: FontWeight.w600, color: AppColors.greenDark),
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

void _openDetails(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _text(20, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text(message, style: _text(14, color: AppColors.grey100)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.name, required this.onOpen});
  final String name;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: _Card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.greenLight,
                child: Text('BS',
                    style: _text(11,
                        weight: FontWeight.w600, color: AppColors.greenDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('KEANGGOTAAN AKTIF',
                        style: _text(10, color: AppColors.grey100)),
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(14, weight: FontWeight.w500)),
                    TextButton(
                      onPressed: onOpen,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text('Detail Bank Sampah'),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.black),
            ],
          ),
        ),
      );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.greenDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'SALDO TABUNGAN',
                    style: _text(11,
                        weight: FontWeight.w500, color: AppColors.greenLight),
                  ),
                ),
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.greenLight),
              ],
            ),
            const SizedBox(height: 10),
            Text('Rp —',
                style: _text(28, weight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Saldo belum tersedia',
                style: _text(12, color: AppColors.greenLight)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Saldo'),
              ),
            ),
          ],
        ),
      );
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.message,
    this.trailing,
  });
  final IconData icon;
  final String message;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) => _Card(
        child: Row(
          children: [
            Icon(icon, color: AppColors.greenDark),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: _text(13))),
            if (trailing != null) Icon(trailing, color: AppColors.grey100),
          ],
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.grey100, size: 26),
            const SizedBox(height: 8),
            Text('Aktivitas belum tersedia',
                style: _text(14, weight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              'Informasi setoran dan aktivitas Anda akan tampil di sini.',
              textAlign: TextAlign.center,
              style: _text(12, color: AppColors.grey100),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onOpen,
              child: const Text('Riwayat Aktivitas'),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: child,
      );
}
