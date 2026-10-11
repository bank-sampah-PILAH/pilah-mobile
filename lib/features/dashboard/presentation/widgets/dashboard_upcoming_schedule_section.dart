import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
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
  late Future<JadwalEntity?> _request;

  @override
  void initState() {
    super.initState();
    _request = _loadNearestSchedule();
  }

  Future<JadwalEntity?> _loadNearestSchedule() async {
    final now = widget.now();
    JadwalEntity? nearest;
    var pageNumber = 1;

    while (true) {
      final result = await widget.repository.getJadwal(
        page: pageNumber,
        date: null,
      );
      final page = result.fold((failure) => throw failure, (page) => page);
      for (final schedule in page.items) {
        final start = schedule.mulaiPada.toLocal();
        if (schedule.isPublished &&
            !start.isBefore(now) &&
            (nearest == null || start.isBefore(nearest.mulaiPada.toLocal()))) {
          nearest = schedule;
        }
      }
      if (page.items.isEmpty || !page.hasMore) return nearest;
      pageNumber++;
    }
  }

  void _retry() {
    final request = _loadNearestSchedule();
    setState(() {
      _request = request;
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal Terdekat',
                style: AppTextStyle.title1.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.go(JadwalPage.route),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<JadwalEntity?>(
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
                        const Expanded(
                          child: Text('Gagal memuat jadwal mendatang.'),
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
              final schedule = snapshot.data;
              if (schedule == null) {
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
                        Text(
                          'Belum ada jadwal mendatang.',
                          style: AppTextStyle.small.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final start = schedule.mulaiPada.toLocal();
              final date = _scheduleDateParam(start);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
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
                                '${formatJadwalDayHeading(start, today: widget.now())} · ${_scheduleTime(start)}',
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
                ),
              );
            },
          ),
        ],
      );
}

String _scheduleDateParam(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _scheduleTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}.'
    '${date.minute.toString().padLeft(2, '0')}';
