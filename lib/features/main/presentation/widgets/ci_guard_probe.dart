import 'package:flutter/material.dart';

/// Throwaway probe, never merged. Every section below breaks one design-system
/// rule on purpose, so CI shows which guard in `test/design/` catches it. The
/// file compiles and passes `flutter analyze`, so only the guard tests go red.
class CiGuardProbe extends StatelessWidget {
  const CiGuardProbe({super.key});

  // hardcoded_styles_test: a raw colour literal.
  static const probeColor = Color(0xFF123456);

  // retired_palette_test: raw colours that were folded into AppColors.
  static const retiredGrey = Color(0xFFF9FAFB);
  static const retiredAmber = Color(0xFFD97706);
  static const retiredGreenTint = Color(0xFFF0FDF4);
  static const retiredRedTint = Color(0xFFFDECEC);

  // single_danger_red_test and single_primary_green_test: copies of a token.
  static const ownDangerRed = Color(0xFFDC2626);
  static const ownPrimaryGreen = Color(0xFF006D44);

  // Opens a bottom sheet by hand (raw_bottom_sheets_test).
  void openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(height: 120),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // hardcoded_app_bars_test: a stock AppBar built in a screen.
      appBar: AppBar(title: const Text('Probe')),
      body: Column(
        children: [
          Container(
            // hardcoded_radius_test: a corner radius written as a number.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              // hardcoded_material_colors_test: a stock Flutter colour.
              color: Colors.grey,
            ),
            child: const Text(
              'Probe',
              style: TextStyle(
                // hardcoded_styles_test: a font size written as a number.
                fontSize: 13,
                // hardcoded_font_weight_test: a stock font weight.
                fontWeight: FontWeight.w600,
                // hardcoded_font_family_test: a typeface named in a screen.
                fontFamily: 'Roboto',
              ),
            ),
          ),
          // raw_buttons_test and hardcoded_button_styles_test: a raw button
          // with its own style.
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: probeColor),
            child: const Text('Probe'),
          ),
          // single_chip_test: a stock choice chip.
          ChoiceChip(
            label: const Text('Probe'),
            selected: false,
            onSelected: (_) {},
          ),
          // hardcoded_input_decoration_test: a per-screen text field look.
          const TextField(decoration: InputDecoration(hintText: 'Probe')),
          // hardcoded_dialogs_test: a dialog built in a screen.
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(title: Text('Probe')),
            ),
            child: const Text('Probe'),
          ),
        ],
      ),
    );
  }
}

// single_rupiah_formatter_test: thousands grouping written by hand.
String formatRupiahId(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return 'Rp $out';
}
