import 'package:pilah_mobile/core/router/app_locations.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_states.dart';

/// Customer home; unavailable personal data is never replaced with bank totals.
class BerandaNasabahPage extends StatelessWidget {
  const BerandaNasabahPage({super.key});

  TextStyle _text(double size,
          {FontWeight weight = FontWeight.w400,
          Color color = NasabahStyle.ink,
          double height = 1.45}) =>
      NasabahStyle.text(size,
          weight: weight, color: color, height: height, tabularFigures: true);
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
              Text(message, style: _text(15, color: NasabahStyle.muted)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Tutup',
                  style: _text(15,
                      weight: FontWeight.w600, color: NasabahStyle.emerald),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            backgroundColor: NasabahStyle.background,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: NasabahStyle.emeraldLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.eco_outlined,
                              color: NasabahStyle.emerald,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('PILAH',
                              style: _text(17, weight: FontWeight.w800)),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Profil',
                            onPressed: ready
                                ? () => context.go(AppLocations.profile)
                                : null,
                            icon: CircleAvatar(
                              radius: 20,
                              backgroundColor: NasabahStyle.emeraldLight,
                              child: Text(
                                name.isEmpty
                                    ? 'N'
                                    : name.characters.first.toUpperCase(),
                                style: _text(
                                  15,
                                  weight: FontWeight.w700,
                                  color: NasabahStyle.emeraldDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Beranda',
                          style: _text(13, color: NasabahStyle.muted)),
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
                          style: _text(13, color: NasabahStyle.muted),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF059669),
                                NasabahStyle.emeraldDark
                              ],
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
                                    color: NasabahStyle.emeraldLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SALDO TABUNGAN',
                                    style: _text(
                                      11,
                                      weight: FontWeight.w600,
                                      color: NasabahStyle.emeraldLight,
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
                                    onPressed: () => _openDetails(
                                      context,
                                      'Saldo',
                                      'Informasi saldo Anda belum tersedia.',
                                    ),
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
                        ),
                        const SizedBox(height: 20),
                        NasabahCard(
                          raised: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    color: NasabahStyle.emerald,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'BANK SAMPAH UNIT',
                                      style: _text(
                                        11,
                                        weight: FontWeight.w600,
                                        color: NasabahStyle.muted,
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
                                  onPressed: () => _openDetails(
                                    context,
                                    'Detail Bank Sampah',
                                    'Unit bank sampah Anda: $unitName',
                                  ),
                                  child: Text(
                                    'Detail Bank Sampah',
                                    style: _text(
                                      13,
                                      weight: FontWeight.w600,
                                      color: NasabahStyle.emerald,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Aktivitas Terbaru',
                          style: _text(17, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        NasabahCard(
                          raised: true,
                          child: Column(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 28,
                                color: NasabahStyle.muted,
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
                                style: _text(13, color: NasabahStyle.muted),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () => _openDetails(
                                  context,
                                  'Riwayat Aktivitas',
                                  'Informasi riwayat aktivitas Anda belum tersedia.',
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: NasabahStyle.line),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Riwayat Aktivitas',
                                  style: _text(
                                    13,
                                    weight: FontWeight.w600,
                                    color: NasabahStyle.emerald,
                                  ),
                                ),
                              ),
                            ],
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
