import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/core/bases/widgets/custom_primary_button.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';

class JadwalPage extends StatefulWidget {
  static const route = '/jadwal';

  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isMonthExpanded = false;
  late final ScrollController _scrollController;
  DateTime? _markerMonth;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadNextPageNearEnd);
    context.read<JadwalCubit>().loadJadwal(date: _selectedDate);
    _loadCalendarDatesFor(_selectedDate);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPageNearEnd)
      ..dispose();
    super.dispose();
  }

  void _loadNextPageNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    context.read<JadwalCubit>().loadNextPage();
  }

  void _loadCalendarDatesFor(DateTime date) {
    final month = DateTime(date.year, date.month);
    _markerMonth = month;
    final first = DateTime(date.year, date.month, 1);
    final offset = first.weekday - DateTime.monday;
    final firstVisible = first.subtract(Duration(days: offset));
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final weekCount = (offset + daysInMonth + 6) ~/ 7;
    final lastVisible = firstVisible.add(Duration(days: weekCount * 7 - 1));
    context.read<JadwalCubit>().loadCalendarDates(
          startDate: firstVisible,
          endDate: lastVisible,
        );
  }

  void _selectDate(DateTime date) {
    final selectedDate = DateUtils.dateOnly(date);
    if (DateUtils.isSameDay(selectedDate, _selectedDate)) return;
    setState(() => _selectedDate = selectedDate);
    context.read<JadwalCubit>().loadJadwal(date: selectedDate);
    final month = DateTime(selectedDate.year, selectedDate.month);
    if (_markerMonth != month) _loadCalendarDatesFor(selectedDate);
  }

  void _navigateCalendar(int direction) {
    if (!_isMonthExpanded) {
      _selectDate(_selectedDate.add(Duration(days: direction * 7)));
      return;
    }

    final firstOfMonth = DateTime(
      _selectedDate.year,
      _selectedDate.month + direction,
    );
    final lastDay = DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    final day = _selectedDate.day > lastDay ? lastDay : _selectedDate.day;
    _selectDate(DateTime(firstOfMonth.year, firstOfMonth.month, day));
  }

  void _openForm([JadwalEntity? initial]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<JadwalCubit>(),
        child: _JadwalForm(
          initial: initial,
          initialDate: initial == null ? _selectedDate : null,
        ),
      ),
    );
  }

  Future<void> _changeStatus(JadwalEntity item, String action) async {
    final failure =
        await context.read<JadwalCubit>().changeStatus(item.id, action);
    if (!mounted || failure == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure.displayMessage)));
  }

  Future<void> _confirmCancellation(JadwalEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan jadwal?'),
        content: const Text('Jadwal yang dibatalkan tidak dapat dipulihkan.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.greenDark),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.greenDark),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _changeStatus(item, 'batalkan');
  }

  Future<void> _confirmCompletion(JadwalEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai jadwal selesai?'),
        content: const Text('Jadwal yang diselesaikan tidak dapat diubah.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.greenDark),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.greenDark),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, selesaikan'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _changeStatus(item, 'selesaikan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Jadwal Kegiatan',
          style: AppTextStyle.headline1.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: BlocBuilder<JadwalCubit, JadwalState>(
        builder: (context, state) => FloatingActionButton(
          heroTag: 'jadwal_page_fab',
          tooltip: 'Buat Jadwal',
          onPressed: state is JadwalLoaded &&
                  (state.isTransitioning || state.isSaving)
              ? null
              : () => _openForm(),
          backgroundColor: AppColors.greenDark,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: BlocBuilder<JadwalCubit, JadwalState>(
        builder: (context, state) {
          if (state is JadwalInitial || state is JadwalLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is JadwalError) {
            return _RetryableMessage(
              message: state.message,
              buttonLabel: 'Coba Lagi',
              onPressed: () =>
                  context.read<JadwalCubit>().loadJadwal(date: _selectedDate),
            );
          }

          final loaded = state as JadwalLoaded;
          final isTransitioning = loaded.isTransitioning;
          final isLifecycleActionDisabled =
              isTransitioning || loaded.isSaving;
          final items = List<JadwalEntity>.of(loaded.items)
            ..sort((a, b) => a.mulaiPada.compareTo(b.mulaiPada));
          final dayItems = items
              .where(
                (item) => DateUtils.isSameDay(
                  item.mulaiPada.toLocal(),
                  _selectedDate,
                ),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () => context
                .read<JadwalCubit>()
                .loadJadwal(silent: true, date: _selectedDate),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
              children: [
                JadwalCalendar(
                  selectedDate: _selectedDate,
                  scheduledDates: loaded.scheduledDates,
                  isMonthExpanded: _isMonthExpanded,
                  onSelectDate: _selectDate,
                  onNavigate: _navigateCalendar,
                  onToggleMonth: () =>
                      setState(() => _isMonthExpanded = !_isMonthExpanded),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        formatJadwalDayHeading(_selectedDate),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${loaded.totalCount} jadwal',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loaded.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dayItems.isEmpty)
                  _EmptyScheduleDay(
                    date: _selectedDate,
                    onCreate: _openForm,
                    onRefresh: () => context
                        .read<JadwalCubit>()
                        .loadJadwal(date: _selectedDate),
                  )
                else
                  ...dayItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ScheduleCard(
                        item: item,
                        onTap: isTransitioning ? null : () => _openForm(item),
                        onCancel: isLifecycleActionDisabled
                            ? null
                            : () => _confirmCancellation(item),
                        onPublish: isLifecycleActionDisabled
                            ? null
                            : () => _changeStatus(item, 'terbitkan'),
                        onComplete: isLifecycleActionDisabled
                            ? null
                            : () => _confirmCompletion(item),
                      ),
                    ),
                  ),
                if (!loaded.isLoading && loaded.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: loaded.loadingMoreError != null
                        ? Center(
                            child: TextButton.icon(
                              onPressed:
                                  context.read<JadwalCubit>().loadNextPage,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba muat lagi'),
                            ),
                          )
                        : loaded.isLoadingMore
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 1),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RetryableMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _RetryableMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.greenDark),
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonLabel),
            ),
          ],
        ),
      );
}

class _EmptyScheduleDay extends StatelessWidget {
  final DateTime date;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  const _EmptyScheduleDay({
    required this.date,
    required this.onCreate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.cardOffWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 36,
            color: AppColors.greenDark.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada jadwal kegiatan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada jadwal pada ${formatJadwalDayHeading(date)}. Jadwal di tanggal lain ditandai dengan titik.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Buat Jadwal'),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppColors.greenDark),
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final JadwalEntity item;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onPublish;
  final VoidCallback? onComplete;

  const _ScheduleCard({
    required this.item,
    required this.onTap,
    required this.onCancel,
    required this.onPublish,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final startsAt = item.mulaiPada.toLocal();
    final endsAt = item.selesaiPada.toLocal();
    final timeRange = DateUtils.isSameDay(startsAt, endsAt)
        ? '${_formatTime(startsAt)} – ${_formatTime(endsAt)}'
        : '${_formatDateTime(startsAt)} – ${_formatDateTime(endsAt)}';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activityLabel(item.jenisKegiatan),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ScheduleInfoLine(
                    icon: Icons.schedule_outlined,
                    text: timeRange,
                  ),
                  const SizedBox(height: 8),
                  _ScheduleInfoLine(
                    icon: Icons.place_outlined,
                    text: item.lokasi,
                  ),
                  if (item.keterangan.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ScheduleInfoLine(
                      icon: Icons.notes_outlined,
                      text: item.keterangan,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ScheduleStatus(status: item.status),
                      const Spacer(),
                      if (item.isOverlapping)
                        const Tooltip(
                          message: 'Jadwal bertumpuk di lokasi yang sama',
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (item.status == 'draft')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.greenDark,
                    ),
                    onPressed: onCancel,
                    child: const Text('Batalkan'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenDark,
                    ),
                    onPressed: onPublish,
                    child: const Text('Terbitkan'),
                  ),
                ],
              ),
            ),
          if (item.status == 'diterbitkan')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.greenDark,
                    ),
                    onPressed: onCancel,
                    child: const Text('Batalkan'),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.greenLight,
                      foregroundColor: AppColors.greenDark,
                    ),
                    onPressed: onComplete,
                    child: const Text('Tandai Selesai'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ScheduleInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      );
}

class _ScheduleStatus extends StatelessWidget {
  final String status;

  const _ScheduleStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    final background = switch (status) {
      'draft' => const Color(0xFFFFF4DE),
      'diterbitkan' => AppColors.greenLight,
      'dibatalkan' => const Color(0xFFFDECEC),
      'selesai' => const Color(0xFFF0F2F0),
      _ => AppColors.cardOffWhite,
    };
    final foreground = switch (status) {
      'draft' => const Color(0xFF8A5A00),
      'diterbitkan' => AppColors.greenDark,
      'dibatalkan' => const Color(0xFF9B3D3D),
      'selesai' => const Color(0xFF59665C),
      _ => Colors.grey.shade700,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _activityLabel(String activity) => switch (activity) {
      'penimbangan' => 'Penimbangan Sampah',
      'pencairan' => 'Pencairan Dana',
      _ => activity,
    };

String _formatTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

class _JadwalForm extends StatefulWidget {
  final JadwalEntity? initial;
  final DateTime? initialDate;

  const _JadwalForm({this.initial, this.initialDate});

  @override
  State<_JadwalForm> createState() => _JadwalFormState();
}

class _JadwalFormState extends State<_JadwalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late String _activity;
  late String _audience;
  late DateTime _startsAt;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _locationController = TextEditingController(text: initial?.lokasi ?? '');
    _descriptionController = TextEditingController(
      text: initial?.keterangan ?? '',
    );
    _activity = initial?.jenisKegiatan ?? 'penimbangan';
    _audience = initial?.cakupanPenerima ?? 'semua_nasabah';
    _startsAt =
        initial?.mulaiPada.toLocal() ?? _defaultStartTime(widget.initialDate);
    _endsAt = initial?.selesaiPada.toLocal() ??
        _startsAt.add(const Duration(hours: 2));
  }

  DateTime _defaultStartTime(DateTime? date) {
    if (date == null) return DateTime.now().add(const Duration(days: 1));

    final selectedDate = DateUtils.dateOnly(date);
    final preferred = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
    );
    final now = DateTime.now();
    if (!DateUtils.isSameDay(selectedDate, now) || preferred.isAfter(now)) {
      return preferred;
    }

    final nextHour = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).add(const Duration(hours: 1));
    return DateUtils.isSameDay(nextHour, selectedDate)
        ? nextHour
        : now.add(const Duration(minutes: 1));
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: AppTextStyle.extraSmall.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _buildInputDecoration({String? hintText}) => InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _startsAt : _endsAt;
    final currentDate = DateUtils.dateOnly(current);
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = currentDate.isBefore(today) ? currentDate : today;
    final lastDate = today.add(const Duration(days: 730));
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate.isAfter(lastDate) ? lastDate : currentDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        final duration = _endsAt.difference(_startsAt);
        _startsAt = value;
        _endsAt = value.add(
          duration.isNegative ? const Duration(hours: 2) : duration,
        );
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.initial == null && _startsAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu mulai harus di masa depan')),
      );
      return;
    }
    if (!_endsAt.isAfter(_startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus setelah waktu mulai'),
        ),
      );
      return;
    }
    final initial = widget.initial;
    final failure = await context.read<JadwalCubit>().saveJadwal(
          JadwalEntity(
            id: initial?.id ?? '',
            bankSampahId: initial?.bankSampahId ?? '',
            jenisKegiatan: _activity,
            mulaiPada: _startsAt,
            selesaiPada: _endsAt,
            lokasi: _locationController.text,
            keterangan: _descriptionController.text,
            cakupanPenerima: _audience,
            penerimaIds: initial?.penerimaIds ?? const [],
            status: initial?.status ?? 'draft',
            isOverlapping: initial?.isOverlapping ?? false,
          ),
        );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.displayMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        key: const ValueKey('jadwal-form'),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BottomSheetHeader(
                  title: widget.initial == null ? 'Buat Jadwal' : 'Ubah Jadwal',
                ),
                const SizedBox(height: 24),
                _buildLabel('JENIS KEGIATAN'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _activity,
                  decoration: _buildInputDecoration(),
                  items: const [
                    DropdownMenuItem(
                      value: 'penimbangan',
                      child: Text('Penimbangan'),
                    ),
                    DropdownMenuItem(
                      value: 'pencairan',
                      child: Text('Pencairan'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _activity = value!),
                ),
                const SizedBox(height: 20),
                _buildLabel('LOKASI'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: _buildInputDecoration(hintText: 'Lokasi'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lokasi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 20),
                _buildLabel('KETERANGAN'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration(hintText: 'Keterangan'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                _DateTimeTile(
                  key: const ValueKey('jadwal-mulai'),
                  label: 'Mulai',
                  value: _startsAt,
                  decoration: _buildInputDecoration(),
                  onTap: () => _pickDateTime(start: true),
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  key: const ValueKey('jadwal-selesai'),
                  label: 'Selesai',
                  value: _endsAt,
                  decoration: _buildInputDecoration(),
                  onTap: () => _pickDateTime(start: false),
                ),
                const SizedBox(height: 20),
                _buildLabel('CAKUPAN PENERIMA'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _audience,
                  decoration: _buildInputDecoration(),
                  items: [
                    const DropdownMenuItem(
                      value: 'semua_nasabah',
                      child: Text('Semua nasabah'),
                    ),
                    if (widget.initial?.cakupanPenerima == 'nasabah_terpilih')
                      const DropdownMenuItem(
                        value: 'nasabah_terpilih',
                        child: Text('Nasabah terpilih'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _audience = value!),
                ),
                const SizedBox(height: 24),
                BlocBuilder<JadwalCubit, JadwalState>(
                  builder: (context, state) {
                    final isSaving = state is JadwalLoaded && state.isSaving;
                    return SizedBox(
                      width: double.infinity,
                      child: CustomPrimaryButton(
                        title: isSaving
                            ? 'Menyimpan...'
                            : widget.initial == null
                                ? 'Simpan Jadwal'
                                : 'Simpan Perubahan',
                        onPressed: isSaving ? null : _submit,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime value;
  final InputDecoration decoration;
  final VoidCallback onTap;

  const _DateTimeTile({
    super.key,
    required this.label,
    required this.value,
    required this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: InputDecorator(
          decoration: decoration.copyWith(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(_formatDateTime(value)),
        ),
      );
}

String _formatDateTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}, '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String _statusLabel(String status) => switch (status) {
      'draft' => 'Draf',
      'diterbitkan' => 'Diterbitkan',
      'dibatalkan' => 'Dibatalkan',
      'selesai' => 'Selesai',
      _ => status,
    };
