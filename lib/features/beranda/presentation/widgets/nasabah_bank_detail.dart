import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// The single rendering of a nasabah's bank sampah — its identity, place in
/// the network, and how to reach it. Shared by the standalone bank page and
/// the beranda "Detail Bank Sampah" sheet so the two never drift apart.
class NasabahBankDetail extends StatelessWidget {
  const NasabahBankDetail({super.key, required this.bank});
  final NasabahBank bank;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NasabahCard(
            padding: 24,
            radius: 24,
            child: Column(
              children: [
                _BankLogo(name: bank.name, logoUrl: bank.logoUrl),
                const SizedBox(height: 16),
                Text(
                  bank.name,
                  textAlign: TextAlign.center,
                  style: NasabahStyle.text(20, weight: FontWeight.w700),
                ),
                if (_organizationLabel(bank.organizationType)
                    case final label?) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: NasabahStyle.emeraldLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(label,
                        style: NasabahStyle.text(13,
                            weight: FontWeight.w600,
                            color: NasabahStyle.emeraldDark)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          NasabahCard(
            padding: 0,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'ALAMAT',
                  value: bank.address.isEmpty
                      ? 'Alamat belum tersedia'
                      : bank.address,
                ),
                const Divider(height: 1, color: NasabahStyle.line),
                _InfoRow(
                  icon: Icons.location_city_outlined,
                  label: 'KOTA',
                  value: bank.city.isEmpty ? 'Kota belum tersedia' : bank.city,
                ),
                const Divider(height: 1, color: NasabahStyle.line),
                _InfoRow(
                  icon: Icons.call_outlined,
                  label: 'KONTAK PIC',
                  value:
                      bank.phone.isEmpty ? 'Kontak belum tersedia' : bank.phone,
                  trailing: bank.phone.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hubungi PIC',
                          icon: const Icon(Icons.call,
                              color: NasabahStyle.emerald),
                          onPressed: () => _call(bank.phone),
                        ),
                ),
              ],
            ),
          ),
        ],
      );

  static Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      // No dialer available on this device/platform — nothing to recover.
    }
  }
}

String? _organizationLabel(String? type) => switch (type) {
      'induk' => 'Bank Sampah Induk',
      'unit' => 'Unit Bank Sampah',
      _ => null, // 'mandiri' (or unknown) tells a nasabah nothing new.
    };

class _BankLogo extends StatelessWidget {
  const _BankLogo({required this.name, required this.logoUrl});
  final String name;
  final String? logoUrl;
  static const double _diameter = 84;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl;
    if (url == null || url.isEmpty) return _initials;
    return ClipOval(
      child: Image.network(
        url,
        width: _diameter,
        height: _diameter,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _initials,
        errorBuilder: (_, __, ___) => _initials,
      ),
    );
  }

  Widget get _initials => CircleAvatar(
        radius: _diameter / 2,
        backgroundColor: NasabahStyle.emeraldLight,
        child: Text(
          _initialOf(name),
          style: NasabahStyle.text(28,
              weight: FontWeight.w700, color: NasabahStyle.emeraldDark),
        ),
      );

  // Most bank sampah names are literally "Bank Sampah <place>", which would
  // otherwise render every missing-logo fallback as the same "B".
  static String _initialOf(String name) {
    final stripped =
        name.replaceFirst(RegExp(r'^bank sampah\s+', caseSensitive: false), '');
    final letters = stripped.isEmpty ? name : stripped;
    return letters.isEmpty ? 'B' : letters.characters.first.toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.trailing});
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: NasabahStyle.emerald),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: NasabahStyle.text(11,
                          weight: FontWeight.w600, color: NasabahStyle.muted)),
                  const SizedBox(height: 4),
                  Text(value, style: NasabahStyle.text(15)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
