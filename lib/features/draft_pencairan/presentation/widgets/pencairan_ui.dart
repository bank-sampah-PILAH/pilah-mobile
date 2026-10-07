import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';

/// The look of Catat Pencairan, shared by the draft screens so they read as
/// one flow: a grey rounded back button, bold title, spaced section labels,
/// white 12px inputs, pill chips and soft cards.

const _emerald = Color(0xFF006D44);

/// Title row with the app's grey rounded back button. Going back uses
/// `maybePop`, so a screen guarding unsaved edits with a `PopScope` is asked.
class PencairanHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const PencairanHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          InkWell(
            key: const Key('kembali'),
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey[800], size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.headline1.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// `PILIH NASABAH`-style heading above a group of fields.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      );
}

InputDecoration pencairanInputDecoration({String? hintText}) => InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyle.small.copyWith(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.greenDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

/// Text style of what is typed into a [pencairanInputDecoration] field.
TextStyle get pencairanInputStyle =>
    AppTextStyle.small.copyWith(color: Colors.black87);

/// A pill: solid green when selected, light grey otherwise.
class PencairanChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const PencairanChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenDark : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyle.small.copyWith(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Soft grey box, like the saldo card on Catat Pencairan.
class PencairanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const PencairanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: child,
      );
}

class SummaryRow {
  final String label;
  final String value;
  final bool emphasized;
  final Key? valueKey;

  const SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueKey,
  });
}

/// White card with a soft shadow and dividers, like Ringkasan on Catat Pencairan.
class PencairanSummaryCard extends StatelessWidget {
  final List<SummaryRow> rows;

  const PencairanSummaryCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),
            _row(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(SummaryRow row) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            row.label,
            style: AppTextStyle.small.copyWith(
              color: row.emphasized ? Colors.black87 : Colors.grey[500],
              fontWeight: row.emphasized ? FontWeight.bold : FontWeight.normal,
              fontSize: row.emphasized ? 16 : null,
            ),
          ),
          Text(
            row.value,
            key: row.valueKey,
            style:
                (row.emphasized ? AppTextStyle.headline1 : AppTextStyle.title1)
                    .copyWith(
              color: row.emphasized ? _emerald : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: row.emphasized ? 20 : 15,
            ),
          ),
        ],
      );
}
