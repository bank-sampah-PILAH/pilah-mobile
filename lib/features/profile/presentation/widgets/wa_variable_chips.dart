import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The tappable variable chips under the WhatsApp template editor. Tapping a
/// chip inserts its `{token}` into the template via [onInsert].
///
/// Kept as its own widget (rather than inline in the settings page) so the chip
/// list — including the `{daftar_item_harga}` augmentation below — can be
/// widget-tested without the page's cubit, bloc, and service-locator wiring.
class WaVariableChips extends StatelessWidget {
  /// The variable tokens advertised by the backend (`variabel_tersedia`).
  final List<String> variables;

  /// Called with the tapped token, e.g. `{daftar_item_harga}`.
  final ValueChanged<String> onInsert;

  const WaVariableChips({
    super.key,
    required this.variables,
    required this.onInsert,
  });

  /// Short, human descriptions shown as each chip's tooltip. The two item-list
  /// variables are the ones users confuse, so their descriptions spell out
  /// exactly what each includes.
  static const Map<String, String> descriptions = {
    '{Nama}': 'Nama nasabah',
    '{Total}': 'Total nilai setoran',
    '{Saldo}': 'Saldo tabungan nasabah',
    '{Tanggal}': 'Tanggal transaksi',
    '{daftar_item}': 'Daftar item & berat',
    '{daftar_item_harga}': 'Daftar item, berat, & harga',
  };

  /// Ensures `{daftar_item_harga}` appears right after `{daftar_item}` in the
  /// chip list. `{daftar_item_harga}` is a client-side preview variable that the
  /// backend does not yet advertise, so it is surfaced regardless of what the
  /// server returns — inserted after `{daftar_item}`, appended if that is absent,
  /// and left untouched if the source already includes it.
  static List<String> withDaftarItemHarga(List<String> source) {
    if (source.contains('{daftar_item_harga}')) return source;
    final result = List<String>.from(source);
    final index = result.indexOf('{daftar_item}');
    if (index == -1) {
      result.add('{daftar_item_harga}');
    } else {
      result.insert(index + 1, '{daftar_item_harga}');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = withDaftarItemHarga(variables);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final token in tokens) _chip(token)],
    );
  }

  Widget _chip(String label) {
    final description = descriptions[label];
    final chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onInsert(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.greenLight.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.greenLight, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 14, color: AppColors.greenDark),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyle.small.copyWith(
                  color: AppColors.greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (description == null) return chip;
    return Tooltip(message: description, child: chip);
  }
}
