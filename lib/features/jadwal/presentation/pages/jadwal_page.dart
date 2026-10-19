import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/layout/app_page_header.dart';
import 'package:pilah_mobile/design/widgets/app_date_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/main/presentation/widgets/web_content_surface.dart';
import 'package:pilah_mobile/core/bases/widgets/app_confirm_dialog.dart';
import 'package:pilah_mobile/core/bases/widgets/bottom_sheet_header.dart';
import 'package:pilah_mobile/design/constants/radius.dart';
import 'package:pilah_mobile/design/widgets/app_button.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/layout/layout_breakpoint.dart';
import 'package:pilah_mobile/design/layout/master_detail_layout.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_field_label.dart';
import 'package:pilah_mobile/design/widgets/nasabah_page_app_bar.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:pilah_mobile/features/jadwal/domain/entities/jadwal_status.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_cubit.dart';
import 'package:pilah_mobile/features/jadwal/presentation/cubit/jadwal_state.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_calendar.dart';
import 'package:pilah_mobile/features/jadwal/presentation/widgets/jadwal_upcoming_dates.dart';
import 'package:pilah_mobile/design/widgets/app_tap_target.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';

class JadwalPage extends StatefulWidget {
  static const route = '/jadwal';
  final bool customerMode;
  final DateTime? initialDate;

  const JadwalPage({super.key, this.customerMode = false, this.initialDate});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late DateTime _selectedDate;
  bool _isMonthExpanded = false;
  late final ScrollController _scrollController;
  DateTime? _markerMonth;

  /// Apakah panel form sedang terbuka di samping agenda. Hanya dipakai pada
  /// expanded; di bawah itu form dibuka sebagai bottom sheet, lihat [_openForm].
  bool _panelOpen = false;
  JadwalEntity? _panelInitial;

  /// Agenda Pengurus di jendela expanded memuat dari tanggal terpilih sampai
  /// akhir bulan; selain itu satu hari saja.
  late bool _rangeMode;

  bool _wantsRange(LayoutBreakpoint breakpoint) =>
      !widget.customerMode && breakpoint == LayoutBreakpoint.expanded;

  /// Memuat agenda untuk [date] sesuai [_rangeMode]. Tanpa rentang, argumen
  /// `dateTo` tidak dikirim sama sekali.
  Future<void> _loadAgenda(DateTime date, {bool silent = false}) {
    final cubit = context.read<JadwalCubit>();
    final end = _rangeMode ? DateTime(date.year, date.month + 1, 0) : null;
    if (end == null) {
      return silent
          ? cubit.loadJadwal(silent: true, date: date)
          : cubit.loadJadwal(date: date);
    }
    return silent
        ? cubit.loadJadwal(silent: true, date: date, dateTo: end)
        : cubit.loadJadwal(date: date, dateTo: end);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _scrollController = ScrollController()..addListener(_loadNextPageNearEnd);
    // Belum boleh berlangganan MediaQuery di sini; lebar dibaca tanpa
    // dependensi dan didChangeDependencies menjaga perubahannya.
    final width =
        context.getInheritedWidgetOfExactType<MediaQuery>()?.data.size.width;
    _rangeMode = _wantsRange(LayoutBreakpoint.fromWidth(width ?? 0));
    _loadAgenda(_selectedDate);
    context.read<JadwalCubit>().loadUpcomingDates();
    _loadCalendarDatesFor(_selectedDate);
  }

  /// Menutup panel ketika jendela berhenti menjadi expanded.
  ///
  /// [_openForm] memilih wadah sekali, saat dibuka, tetapi lebar jendela dapat
  /// berubah setelah itu — dan tanpa ini panel yang sudah terbuka justru
  /// berakhir di lebar yang [_openForm] sengaja hindari. Pada medium
  /// [MasterDetailLayout] tetap merender detail, jadi form berada di panel 2/5
  /// yang sekitar 320 piksel. Pada compact ia melepas detail sama sekali, jadi
  /// form dibuang sementara [_panelOpen] tetap true: halaman kehilangan
  /// formnya dan tidak punya apa pun untuk ditutup.
  ///
  /// Dengan ini syarat "panel hanya ada pada expanded" berlaku terus, bukan
  /// hanya pada saat dibuka. Mengecilkan jendela mengembalikan lebar penuh ke
  /// agenda, dan menekan tombol tambah lagi memberi bottom sheet, wadah yang
  /// memang benar untuk lebar itu.
  ///
  /// `MediaQuery` dibaca sebagai dependensi, sehingga method ini ikut
  /// terpanggil setiap kali ukuran jendela berubah. Field diubah langsung
  /// tanpa `setState` karena build selalu menyusul.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_panelOpen && context.layoutBreakpoint != LayoutBreakpoint.expanded) {
      _panelOpen = false;
      _panelInitial = null;
    }
    final wantsRange = _wantsRange(context.layoutBreakpoint);
    if (wantsRange != _rangeMode) {
      _rangeMode = wantsRange;
      // Memuat mengubah state kubit, yang tidak boleh terjadi di tengah build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAgenda(_selectedDate);
      });
    }
  }

  @override
  void didUpdateWidget(covariant JadwalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final requestedDate = widget.initialDate;
    if (requestedDate != null) {
      _selectDate(requestedDate);
    } else if (oldWidget.initialDate != null) {
      _selectDate(DateTime.now());
    }
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
    _loadAgenda(selectedDate);
    final month = DateTime(selectedDate.year, selectedDate.month);
    if (_markerMonth != month) _loadCalendarDatesFor(selectedDate);
  }

  void _navigateCalendar(int direction, {bool wholeMonth = false}) {
    if (!wholeMonth && !_isMonthExpanded) {
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
    // Hanya expanded, bukan medium. Pada medium panel hanya mendapat dua dari
    // lima bagian lebar, sekitar 320 piksel, dan form ini berisi dropdown serta
    // dua pemilih tanggal yang tidak muat di sana. Di bawah expanded bottom
    // sheet tetap wadah yang lebih baik.
    if (context.layoutBreakpoint == LayoutBreakpoint.expanded) {
      setState(() {
        _panelOpen = true;
        _panelInitial = initial;
      });
      return;
    }

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

  void _closePanel() {
    if (!_panelOpen) return;
    setState(() {
      _panelOpen = false;
      _panelInitial = null;
    });
  }

  /// Form sebagai panel di samping agenda, atau null bila tidak ada yang
  /// sedang disunting. [MasterDetailLayout] sendiri yang mengabaikannya pada
  /// compact, sehingga telepon tetap memakai bottom sheet.
  Widget? _buildFormPanel() {
    if (!_panelOpen) return null;
    return _JadwalForm(
      key: ValueKey('jadwal-panel-${_panelInitial?.id ?? 'baru'}'),
      initial: _panelInitial,
      initialDate: _panelInitial == null ? _selectedDate : null,
      onClose: _closePanel,
    );
  }

  Future<void> _changeStatus(JadwalEntity item, JadwalAction action) async {
    final failure = await context.read<JadwalCubit>().changeStatus(
          item.id,
          action.wireValue,
        );
    if (!mounted || failure == null) return;
    AppNotification.showError(
      context,
      title: 'Gagal',
      message: failure.displayMessage,
    );
  }

  Future<void> _confirmCancellation(JadwalEntity item) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Batalkan jadwal?',
      message: 'Jadwal yang dibatalkan tidak dapat dipulihkan.',
      confirmLabel: 'Ya, batalkan',
      cancelLabel: 'Kembali',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    await _changeStatus(item, JadwalAction.batalkan);
  }

  Future<void> _confirmCompletion(JadwalEntity item) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Tandai jadwal selesai?',
      message: 'Jadwal yang diselesaikan tidak dapat diubah.',
      confirmLabel: 'Ya, selesaikan',
      cancelLabel: 'Kembali',
      destructive: false,
    );
    if (!mounted || !confirmed) return;
    await _changeStatus(item, JadwalAction.selesaikan);
  }

  /// Pengurus di layar lebar memakai kepala halaman yang sama dengan tab web
  /// lain, di dalam daftar, bukan `AppBar`.
  bool get _webHeader =>
      !widget.customerMode &&
      context.layoutBreakpoint != LayoutBreakpoint.compact;

  /// Di jendela expanded "Buat Jadwal" ada di kepala halaman seperti tab web
  /// lain, bukan tombol mengambang; di bawahnya tombol mengambang tetap.
  bool get _createInHeader =>
      !widget.customerMode &&
      context.layoutBreakpoint == LayoutBreakpoint.expanded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          WebContentSurface.pageColor(context, phone: Colors.white),
      appBar: widget.customerMode
          ? const NasabahPageAppBar(title: 'Jadwal Bank Sampah')
          : _webHeader
              ? null
              : AppBar(
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
      floatingActionButton: widget.customerMode || _createInHeader
          ? null
          : BlocBuilder<JadwalCubit, JadwalState>(
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
              onPressed: () => _loadAgenda(_selectedDate),
            );
          }

          final loadedState = state as JadwalLoaded;
          final visibleItems = widget.customerMode
              ? loadedState.items
                  .where(
                    (item) =>
                        item.status == 'diterbitkan' &&
                        DateUtils.isSameDay(
                          item.mulaiPada.toLocal(),
                          _selectedDate,
                        ),
                  )
                  .toList()
              : loadedState.items;
          final items = List<JadwalEntity>.of(visibleItems)
            ..sort((a, b) => a.mulaiPada.compareTo(b.mulaiPada));
          return RefreshIndicator(
            onRefresh: () => _loadAgenda(_selectedDate, silent: true),
            child: widget.customerMode
                ? _buildCustomerAgenda(items, loadedState)
                : MasterDetailLayout(
                    master: _buildPengurusAgenda(items, loadedState),
                    detail: _buildFormPanel(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerAgenda(
    List<JadwalEntity> items,
    JadwalLoaded loadedState,
  ) {
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        JadwalCalendar(
          selectedDate: _selectedDate,
          scheduledDates: loadedState.scheduledDates,
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
              '${loadedState.totalCount} jadwal',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loadedState.isLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
          _CustomerEmptyScheduleDay(
            date: _selectedDate,
            onRefresh: () => _loadAgenda(_selectedDate),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScheduleCard(
                item: item,
                onTap: null,
                onCancel: null,
                onPublish: null,
                onComplete: null,
                readOnly: true,
              ),
            ),
          ),
        if (!loadedState.isLoading && loadedState.hasMore)
          _buildLoadMoreFooter(loadedState),
      ],
    );
  }

  Widget _buildPengurusAgenda(
    List<JadwalEntity> items,
    JadwalLoaded loadedState,
  ) {
    final dayItems = _rangeMode
        ? items
        : items
            .where(
              (item) =>
                  DateUtils.isSameDay(item.mulaiPada.toLocal(), _selectedDate),
            )
            .toList();

    // Lebar daftar, bukan jendela: dengan panel form terbuka daftar tinggal
    // sebagian lebar dan kembali bertumpuk.
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            _webHeader && constraints.maxWidth >= _sideBySideMinWidth;
        final calendar = JadwalCalendar(
          selectedDate: _selectedDate,
          scheduledDates: loadedState.scheduledDates,
          isMonthExpanded: sideBySide || _isMonthExpanded,
          showToggle: !sideBySide,
          onSelectDate: _selectDate,
          onNavigate: (direction) =>
              _navigateCalendar(direction, wholeMonth: sideBySide),
          onToggleMonth: () =>
              setState(() => _isMonthExpanded = !_isMonthExpanded),
        );
        final agenda = _pengurusAgendaChildren(dayItems, loadedState);
        final header = [
          AppPageHeader(
            title: 'Jadwal Kegiatan',
            actions: [
              if (_createInHeader)
                AppButton(
                  label: 'Buat Jadwal',
                  icon: Icons.add,
                  expand: false,
                  onPressed: loadedState.isTransitioning || loadedState.isSaving
                      ? null
                      : _openForm,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ];
        if (sideBySide) {
          // Kalender dan "Berikutnya" diam di kiri; hanya agenda yang
          // bergulir, jadi kolom kiri tidak kosong saat agenda panjang.
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.webGutter,
              AppSpacing.webTop,
              AppSpacing.webGutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _sideCalendarWidth,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              calendar,
                              const SizedBox(height: AppSpacing.lg),
                              JadwalUpcomingDates(
                                upcomingDates: loadedState.upcomingDates,
                                today: clock.now(),
                                selectedDate: _selectedDate,
                                onSelect: _selectDate,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        child: ListView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          children: agenda,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _webHeader
              ? const EdgeInsets.fromLTRB(
                  AppSpacing.webGutter,
                  AppSpacing.webTop,
                  AppSpacing.webGutter,
                  104,
                )
              : const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            if (_webHeader) ...header,
            calendar,
            const SizedBox(height: 24),
            ...agenda,
          ],
        );
      },
    );
  }

  /// Daftar lebar daftar jadwal yang cukup untuk kalender di samping agenda.
  static const _sideBySideMinWidth = 900.0;
  static const _sideCalendarWidth = 400.0;

  /// Judul hari, kartu jadwal (atau keadaan kosong), dan pemuat berikutnya.
  ///
  /// Satu hari: [items] sudah hanya hari terpilih. Rentang: [items] adalah sisa
  /// bulan; tiap hari berjadwal mendapat judul sendiri, dan hari terpilih
  /// selalu tampil, kosong atau tidak, sebagai titik awal.
  List<Widget> _pengurusAgendaChildren(
    List<JadwalEntity> items,
    JadwalLoaded loadedState,
  ) {
    final byDay = <DateTime, List<JadwalEntity>>{};
    for (final item in items) {
      byDay
          .putIfAbsent(DateUtils.dateOnly(item.mulaiPada.toLocal()), () => [])
          .add(item);
    }
    final days = (_rangeMode ? {_selectedDate, ...byDay.keys} : {_selectedDate})
        .toList()
      ..sort();
    return [
      for (var i = 0; i < days.length; i++) ...[
        if (i > 0) const SizedBox(height: 12),
        ..._dayAgenda(
          days[i],
          byDay[days[i]] ?? const [],
          // Satu hari memakai jumlah dari server; rentang menghitung per hari.
          _rangeMode
              ? (byDay[days[i]] ?? const []).length
              : loadedState.totalCount,
          loadedState,
        ),
      ],
      if (!loadedState.isLoading && loadedState.hasMore)
        _buildLoadMoreFooter(loadedState),
    ];
  }

  List<Widget> _dayAgenda(
    DateTime day,
    List<JadwalEntity> dayItems,
    int count,
    JadwalLoaded loadedState,
  ) {
    final isTransitioning = loadedState.isTransitioning;
    final isLifecycleActionDisabled = isTransitioning || loadedState.isSaving;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              formatJadwalDayHeading(day),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$count jadwal',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (dayItems.isEmpty)
        _EmptyScheduleDay(
          date: day,
          onCreate: _openForm,
          onRefresh: () => _loadAgenda(_selectedDate),
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
                  : () => _changeStatus(item, JadwalAction.terbitkan),
              onComplete: isLifecycleActionDisabled
                  ? null
                  : () => _confirmCompletion(item),
            ),
          ),
        ),
    ];
  }

  Widget _buildLoadMoreFooter(JadwalLoaded loadedState) {
    if (loadedState.loadingMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: context.read<JadwalCubit>().loadNextPage,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba muat lagi'),
        ),
      );
    }
    if (loadedState.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox(height: 1);
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
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonLabel),
            ),
          ],
        ),
      );
}

class _CustomerEmptyScheduleDay extends StatelessWidget {
  final DateTime date;
  final VoidCallback onRefresh;

  const _CustomerEmptyScheduleDay({
    required this.date,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Container(
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
              'Tidak ada jadwal pada ${formatJadwalDayHeading(date)}. Tanggal dengan jadwal ditandai titik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat Ulang'),
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
          // Penuh lebar di ponsel, tetapi tidak melebar di agenda web.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Buat Jadwal'),
              ),
            ),
          ),
          TextButton.icon(
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
  final bool readOnly;

  const _ScheduleCard({
    required this.item,
    required this.onTap,
    required this.onCancel,
    required this.onPublish,
    required this.onComplete,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final startsAt = item.mulaiPada.toLocal();
    final endsAt = item.selesaiPada.toLocal();
    final timeRange = DateUtils.isSameDay(startsAt, endsAt)
        ? '${_formatTime(startsAt)} – ${_formatTime(endsAt)}'
        : '${_formatDateTime(startsAt)} – ${_formatDateTime(endsAt)}';

    // Seluruh kartu satu area ketuk, termasuk baris aksi: hover dan riak
    // menutup kartu sampai sudut membulat. Tombol aksi menangkap ketukannya
    // sendiri, jadi menekannya tidak ikut membuka formulir.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.greenLight.withValues(alpha: 0.45),
        child: Column(
          children: [
            Padding(
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
                      if (!readOnly && item.isOverlapping)
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
            if (!readOnly && _availableActions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    for (final action in _availableActions)
                      _actionButton(action),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Aksi yang sah dari status jadwal ini.
  ///
  /// Status yang tidak dikenali build ini tidak memberi aksi apa pun, bukan
  /// aksi penuh: pengurus melihat kartunya tetapi tidak dapat mengubahnya.
  Set<JadwalAction> get _availableActions =>
      JadwalStatus.fromWire(item.status)?.availableActions ?? const {};

  Widget _actionButton(JadwalAction action) => switch (action) {
        JadwalAction.batalkan => TextButton(
            onPressed: onCancel,
            child: Text(action.label),
          ),
        JadwalAction.terbitkan => FilledButton(
            onPressed: onPublish,
            child: Text(action.label),
          ),
        JadwalAction.selesaikan => AppButton(
            label: action.label,
            variant: AppButtonVariant.tonal,
            expand: false,
            onPressed: onComplete,
          ),
      };
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
    final resolved = JadwalStatus.fromWire(status);
    final (background, foreground) = switch (resolved) {
      JadwalStatus.draf => (AppColors.warningLight, AppColors.warning),
      JadwalStatus.diterbitkan => (AppColors.greenLight, AppColors.greenDark),
      JadwalStatus.dibatalkan => (AppColors.dangerLight, AppColors.danger),
      JadwalStatus.selesai => (AppColors.fill, AppColors.inkSoft),
      null => (AppColors.cardOffWhite, Colors.grey.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        resolved?.label ?? status,
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

  /// Diisi hanya ketika form tampil sebagai panel. Panel tidak berada di atas
  /// navigator, jadi ia ditutup lewat callback, bukan dengan `Navigator.pop`.
  /// Nilainya sekaligus menjadi penanda wadah: null berarti bottom sheet.
  final VoidCallback? onClose;

  const _JadwalForm({
    super.key,
    this.initial,
    this.initialDate,
    this.onClose,
  });

  /// Apakah form sedang tampil sebagai panel, bukan sebagai bottom sheet.
  bool get isPanel => onClose != null;

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
    // coverage:ignore-start
    // Defensive: _openForm always passes the selected date for a new schedule
    // and an existing one carries its own start time.
    if (date == null) return DateTime.now().add(const Duration(days: 1));
    // coverage:ignore-end

    final selectedDate = DateUtils.dateOnly(date);
    final preferred = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      9,
    );
    final now = clock.now();
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

  Future<void> _pickDateTime({required bool start}) async {
    final current = start ? _startsAt : _endsAt;
    final currentDate = DateUtils.dateOnly(current);
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = currentDate.isBefore(today) ? currentDate : today;
    final lastDate = today.add(const Duration(days: 730));
    final date = await showAppDatePicker(
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
      AppNotification.showWarning(
        context,
        title: 'Waktu tidak valid',
        message: 'Waktu mulai harus di masa depan',
      );
      return;
    }
    if (!_endsAt.isAfter(_startsAt)) {
      AppNotification.showWarning(
        context,
        title: 'Waktu tidak valid',
        message: 'Waktu selesai harus setelah waktu mulai',
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
      final close = widget.onClose;
      if (close != null) {
        close();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      AppNotification.showError(
        context,
        title: 'Gagal',
        message: failure.displayMessage,
      );
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
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                  showDragHandle: !widget.isPanel,
                  onClose: widget.onClose,
                ),
                const SizedBox(height: 24),
                const AppFieldLabel('JENIS KEGIATAN'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  initialValue: _activity,
                  decoration: appInputDecoration(),
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
                const AppFieldLabel('LOKASI'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  decoration: appInputDecoration(hintText: 'Lokasi'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Lokasi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 20),
                const AppFieldLabel('KETERANGAN'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: appInputDecoration(hintText: 'Keterangan'),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                _DateTimeTile(
                  key: const ValueKey('jadwal-mulai'),
                  label: 'Mulai',
                  value: _startsAt,
                  decoration: appInputDecoration(),
                  onTap: () => _pickDateTime(start: true),
                ),
                const SizedBox(height: 12),
                _DateTimeTile(
                  key: const ValueKey('jadwal-selesai'),
                  label: 'Selesai',
                  value: _endsAt,
                  decoration: appInputDecoration(),
                  onTap: () => _pickDateTime(start: false),
                ),
                const SizedBox(height: 20),
                const AppFieldLabel('CAKUPAN PENERIMA'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  initialValue: _audience,
                  decoration: appInputDecoration(),
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
                      child: AppButton(
                        label: isSaving
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
  Widget build(BuildContext context) => AppTapTarget(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
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
