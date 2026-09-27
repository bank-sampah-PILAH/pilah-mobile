import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
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

/// One entry in the approval history timeline: an icon+colour per decision,
/// a connecting line to the next entry, the catatan text and the date.
///
/// Adapts the step visual from `pending_approval_screen.dart`'s `_buildStep`
/// (circle + connecting line + title/subtitle) to render an actual decision
/// log entry instead of a fixed onboarding stage.
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.small.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        formatApprovalLogDate(entry.createdAt),
                        style: AppTextStyle.extraSmall,
                      ),
                    ],
                  ),
                  if (entry.catatan.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.catatan,
                      style:
                          AppTextStyle.small.copyWith(color: Colors.grey[600]),
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
