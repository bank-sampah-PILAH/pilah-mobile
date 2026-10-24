import 'package:flutter/material.dart';
// CI benchmark scratch: documentation comment only, no behavior change.
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/repositories/jadwal_repository.dart';
import 'package:pilah_mobile/features/jadwal/presentation/pages/jadwal_page.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';

class DashboardUpcomingScheduleSection extends StatefulWidget {
  final JadwalRepository repository;
  final DateTime Function() now;

  const DashboardUpcomingScheduleSection({
    super.key,
    required this.repository,
    this.now = DateTime.now,
  });

  @override
  State<DashboardUpcomingScheduleSection> createState() =>
      _DashboardUpcomingScheduleSectionState();
}

class _DashboardUpcomingScheduleSectionState
    extends State<DashboardUpcomingScheduleSection> {
  /// Jadwal terdekat yang ditampilkan: tiga cukup memberi gambaran minggu ini
  /// tanpa memanjangkan dashboard.
  static const _shown = 3;

  late Future<List<JadwalEntity>> _request;

  @override
  void initState() {
    super.initState();
    _request = _loadUpcoming();
  }

  Future<List<JadwalEntity>> _loadUpcoming() async {
    final now = widget.now();
    final upcoming = <JadwalEntity>[];
    var pageNumber = 1;

    while (true) {
      final result = await widget.repository.getJadwal(
        page: pageNumber,
        date: null,
      );
      final page = result.fold((failure) => throw failure, (page) => page);
      for (final schedule in page.items) {
        if (schedule.isPublished &&
            !schedule.selesaiPada.toLocal().isBefore(now)) {
          upcoming.add(schedule);
        }
      }
      if (page.items.isEmpty || !page.hasMore) break;
      pageNumber++;
    }
    upcoming.sort((a, b) => a.mulaiPada.compareTo(b.mulaiPada));
    return upcoming.take(_shown).toList();
  }

  void _retry() {
    final request = _loadUpcoming();
    setState(() {
      _request = request;
    });
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          cardTheme: CardThemeData(
            color: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Jadwal Terdekat',
                    style: AppTextStyle.title1.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(JadwalPage.route),
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<JadwalEntity>>(
              future: _request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Card(
                    child: SizedBox(
                      height: 88,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Gagal memuat jadwal mendatang.',
                                style: AppTextStyle.small.copyWith(
                                  color: AppColors.grey100,
                                )),
                          ),
                          TextButton(
                            onPressed: _retry,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final schedules = snapshot.data ?? const <JadwalEntity>[];
                if (schedules.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.greenDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                            'Belum ada jadwal mendatang.',
                            style: AppTextStyle.small.copyWith(
                              color: Colors.grey[600],
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < schedules.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        _ScheduleRow(
                          schedule: schedules[i],
                          today: widget.now(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule, required this.today});

  final JadwalEntity schedule;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final start = schedule.mulaiPada.toLocal();
    final date = _scheduleDateParam(start);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.go(
        Uri(
          path: JadwalPage.route,
          queryParameters: {'date': date},
        ).toString(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.greenDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.jenisKegiatan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.small.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${formatJadwalDayHeading(start, today: today)} · ${_scheduleTime(start)}',
                    style: AppTextStyle.small.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (schedule.lokasi.isNotEmpty)
                    Text(
                      schedule.lokasi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.small.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

String _scheduleDateParam(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _scheduleTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}.'
    '${date.minute.toString().padLeft(2, '0')}';
