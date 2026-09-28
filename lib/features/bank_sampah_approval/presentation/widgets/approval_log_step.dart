import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/expandable_text.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/domain/entities/nasabah_membership_entity.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Formats [dateTimeUtc] (assumed UTC, as parsed from the backend) in the
/// viewer's local time as `d MMM yyyy · HH:mm:ss`, e.g.
/// `20 Sep 2026 · 09:05:03` — a membership can be appealed and decided more
/// than once in the same day, so the date alone doesn't distinguish entries.
///
/// Deliberately hand-rolled rather than `intl`'s `DateFormat`: nothing else in
/// this app initialises an `id_ID` locale, and pulling one in just for this
/// screen would mean every test that renders it also has to call
/// `initializeDateFormatting` first.
String formatApprovalLogDate(DateTime dateTimeUtc) {
  final local = dateTimeUtc.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  final date = '${local.day} ${_monthNames[local.month - 1]} ${local.year}';
  final time = '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  return '$date · $time';
}

/// One recorded decision in the chronological membership timeline.
class ApprovalLogStep extends StatelessWidget {
  final ApprovalLogEntity entry;
  final bool isLast;

  const ApprovalLogStep({super.key, required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.status) {
      ApprovalLogStatus.approved => (Icons.check, AppColors.greenDark),
      ApprovalLogStatus.rejected => (Icons.close, const Color(0xFFC62828)),
      ApprovalLogStatus.appealed => (Icons.forward, const Color(0xFFB26A00)),
    };
    final title = switch (entry.status) {
      ApprovalLogStatus.approved => 'Disetujui',
      ApprovalLogStatus.rejected => 'Ditolak',
      ApprovalLogStatus.appealed => 'Diajukan Banding',
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: NasabahStyle.line),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: NasabahStyle.text(14, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(formatApprovalLogDate(entry.createdAt),
                      style: NasabahStyle.text(12, color: NasabahStyle.muted)),
                  if (entry.catatan.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ExpandableText(
                      text: entry.catatan,
                      style: NasabahStyle.text(13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
