import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:intl/intl.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/form_style.dart';
import 'package:pilah_mobile/design/constants/spacing.dart';
import 'package:pilah_mobile/design/constants/text_style.dart';
import 'package:pilah_mobile/design/widgets/app_dialog.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pilah_mobile/features/dashboard/presentation/providers/recent_activity_provider.dart';
import 'package:pilah_mobile/features/nasabah/presentation/providers/nasabah_provider.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/aktivitas_entity.dart';
import 'package:pilah_mobile/features/transaksi/domain/entities/bulk_void_result.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/aktivitas_selection_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/riwayat_aktivitas_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/providers/transaksi_provider.dart';
import 'package:pilah_mobile/features/transaksi/presentation/states/riwayat_aktivitas_state.dart';

Future<void> showBulkBatalkanSetoranDialog(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final selected = container.read(aktivitasSelectionProvider);
  if (selected == null || selected.isEmpty) return;
  final targets = container
      .read(riwayatAktivitasProvider)
      .items
      .where((item) =>
          item.isSelectableSetoran && selected.contains(item.transaksi!.id))
      .toList();
  // Freeze and order the exact set being confirmed, independent of later refreshes.
  targets.sort((a, b) {
    final dateOrder = (a.tanggal?.millisecondsSinceEpoch ?? 0)
        .compareTo(b.tanggal?.millisecondsSinceEpoch ?? 0);
    return dateOrder != 0
        ? dateOrder
        : a.transaksi!.id.compareTo(b.transaksi!.id);
  });
  if (targets.isEmpty) {
    container.read(aktivitasSelectionProvider.notifier).clear();
    AppNotification.showWarning(
      context,
      title: 'Pilihan tidak tersedia',
      message: 'Pilihan sudah tidak tersedia di riwayat terbaru',
    );
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        BulkBatalkanSetoranDialog(targets: List.unmodifiable(targets)),
  );
}

class BulkBatalkanSetoranDialog extends ConsumerStatefulWidget {
  const BulkBatalkanSetoranDialog({super.key, required this.targets});
  final List<ActivitasEntity> targets;
  @override
  ConsumerState<BulkBatalkanSetoranDialog> createState() =>
      _BulkBatalkanSetoranDialogState();
}

class _BulkBatalkanSetoranDialogState
    extends ConsumerState<BulkBatalkanSetoranDialog> {
  final _alasan = TextEditingController();
  bool _saving = false;
  bool _refreshFailed = false;
  int _completed = 0;
  String? _error;
  BulkVoidResult? _result;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _result != null) return;
    final reason = _alasan.text.trim();
    if (reason.isEmpty || reason.runes.length > 255) {
      setState(() => _error = reason.isEmpty
          ? 'Alasan pembatalan wajib diisi'
          : 'Alasan maksimal 255 karakter');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final notifier = ref.read(transaksiProvider.notifier);
    final session = notifier.sessionKey;
    final result = await notifier.batalkanBeberapaTransaksi(
      ids: widget.targets.map((t) => t.transaksi!.id).toList(),
      alasan: reason,
      canContinue: () => mounted,
      onProgress: (completed, _) {
        if (mounted) setState(() => _completed = completed);
      },
    );
    if (!mounted) return;
    if (notifier.sessionKey != session) {
      ref.read(aktivitasSelectionProvider.notifier).clear();
      Navigator.of(context).pop();
      return;
    }
    await _refreshAffectedViews();
    if (!mounted) return;
    if (notifier.sessionKey != session) {
      ref.read(aktivitasSelectionProvider.notifier).clear();
      Navigator.of(context).pop();
      return;
    }
    final selection = ref.read(aktivitasSelectionProvider.notifier);
    if (result.remainingIds.isEmpty) {
      selection.clear();
    } else {
      selection.retain(result.remainingIds);
    }
    setState(() {
      _result = result;
      _saving = false;
    });
  }

  Future<void> _refreshAffectedViews() async {
    final container = ProviderScope.containerOf(context, listen: false);
    // Only reload caches that already exist; do not construct unrelated screens.
    final reloads = <Future<void>>[
      ref.read(riwayatAktivitasProvider.notifier).load(silent: true),
      if (container.exists(dashboardProvider))
        ref.read(dashboardProvider.notifier).loadStats(),
      if (container.exists(recentActivityProvider))
        ref.read(recentActivityProvider.notifier).load(silent: true),
      if (container.exists(nasabahProvider))
        ref.read(nasabahProvider.notifier).loadNasabah(silent: true),
    ];
    try {
      await Future.wait(reloads);
      if (mounted) {
        _refreshFailed = ref.read(riwayatAktivitasProvider).status ==
            AktivitasStatus.failure;
      }
    } catch (_) {
      _refreshFailed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return PopScope(
      canPop: !_saving,
      child: AppDialog(
        title: result == null
            ? 'Hapus ${widget.targets.length} setoran?'
            : 'Hasil pembatalan',
        content: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: SingleChildScrollView(
            child: result == null ? _confirmation() : _results(result),
          ),
        ),
        confirmLabel: result == null
            ? 'Ya, hapus ${widget.targets.length} setoran'
            : 'Selesai',
        cancelLabel: 'Kembali',
        showCancelAction: result == null,
        destructive: result == null,
        isLoading: _saving,
        onConfirm: result == null ? _submit : () => Navigator.of(context).pop(),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _confirmation() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Setoran disembunyikan dari riwayat dan tidak lagi dihitung '
              'ke saldo nasabah maupun laporan. Saldo nasabah dihitung ulang. '
              'Setoran diproses satu per satu; sebagian dapat ditolak jika saldonya sudah dicairkan.',
              style: AppTextStyle.small),
          const SizedBox(height: AppSpacing.md),
          Text(
              'Alasan yang sama akan dicatat untuk setiap setoran yang berhasil dibatalkan.',
              style: AppTextStyle.small),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('bulk-void-alasan'),
            controller: _alasan,
            enabled: !_saving,
            maxLength: 255,
            maxLines: 2,
            decoration: appInputDecoration(
                hintText: 'Alasan pembatalan',
                errorText: _error,
                focusColor: AppColors.danger),
          ),
          if (_saving) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
                liveRegion: true,
                child: Text(
                    '$_completed dari ${widget.targets.length} setoran selesai diproses.',
                    style: AppTextStyle.small)),
          ],
        ],
      );

  Widget _results(BulkVoidResult result) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${result.berhasil} setoran berhasil dibatalkan.',
              style: AppTextStyle.headline3),
          if (_refreshFailed) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
                'Hasil pembatalan sudah diterima, tetapi riwayat belum berhasil dimuat ulang. Muat ulang sebelum mencoba lagi.',
                style: AppTextStyle.small.copyWith(color: AppColors.danger)),
          ],
          for (final outcome in result.outcomes
              .where((o) => o.status != BulkVoidStatus.berhasil)) ...[
            const SizedBox(height: AppSpacing.lg),
            _outcome(outcome),
          ],
          if (result.remainingIds.isEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
                'Detail setoran tetap menyimpan siapa, kapan, dan alasan pembatalannya.',
                style: AppTextStyle.small),
          ],
        ],
      );

  Widget _outcome(SetoranVoidOutcome outcome) {
    final item =
        widget.targets.firstWhere((t) => t.transaksi!.id == outcome.id);
    final when = item.tanggal == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(item.tanggal!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: AppTextStyle.headline3),
        Text([when, item.amount].where((s) => s.isNotEmpty).join(' • '),
            style: AppTextStyle.small),
        const SizedBox(height: AppSpacing.xs),
        Text(
            switch (outcome.status) {
              BulkVoidStatus.berhasil => 'Berhasil',
              BulkVoidStatus.gagal => 'Gagal',
              BulkVoidStatus.belumDipastikan => 'Status belum dipastikan',
              BulkVoidStatus.belumDiproses => 'Belum diproses',
            },
            style: AppTextStyle.small.copyWith(color: AppColors.danger)),
        if (outcome.message != null)
          Text(outcome.message!, style: AppTextStyle.small),
      ],
    );
  }
}
