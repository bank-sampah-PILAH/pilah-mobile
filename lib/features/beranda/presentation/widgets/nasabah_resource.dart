import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilah_mobile/design/widgets/nasabah_activity_card.dart';
import 'package:pilah_mobile/features/bank_sampah_approval/presentation/pages/approval_bank_sampah_list_page.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/core/utils/formatter/currency_formatter.dart';

/// Owns one request. Re-key on session/selection changes to discard stale data.
///
/// Has no refresh affordance of its own — pull-to-refresh lives on the page's
/// own scrollable (see `AppRefreshIndicator` usages at each call site), which
/// needs a way to trigger a reload here. [registerReload] is that hand-off: the
/// state calls it once, in [initState], with a `reload()` closure the page can
/// store and invoke later from its `RefreshIndicator.onRefresh`.
class NasabahResource<T> extends StatefulWidget {
  const NasabahResource(
      {super.key,
      required this.load,
      required this.builder,
      this.onSelect,
      this.registerReload,
      this.refreshOnResume = false});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final ValueChanged<String>? onSelect;
  final void Function(Future<void> Function() reload)? registerReload;
  final bool refreshOnResume;
  @override
  State<NasabahResource<T>> createState() => NasabahResourceState<T>();
}

class NasabahResourceState<T> extends State<NasabahResource<T>>
    with WidgetsBindingObserver {
  late Future<T> _request;
  @override
  void initState() {
    super.initState();
    if (widget.refreshOnResume) WidgetsBinding.instance.addObserver(this);
    _request = widget.load();
    widget.registerReload?.call(reload);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.refreshOnResume && state == AppLifecycleState.resumed) {
      unawaited(reload());
    }
  }

  @override
  void dispose() {
    if (widget.refreshOnResume) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Reloads and returns a future that settles once the new request does, so
  /// a caller (typically a page-level `RefreshIndicator.onRefresh`) can await
  /// it and keep its spinner up for the right duration.
  Future<void> reload() {
    if (!mounted) return Future<void>.value();
    final future = widget.load();
    setState(() {
      _request = future;
    });
    return future;
  }

  /// What a failed request offers: the reason, the banks to choose from when
  /// the API asked for one (422), and then either a way out or a retry.
  ///
  /// A refusal (403) is the answer rather than a hiccup: the bank stopped
  /// being one this nasabah may open, so reloading cannot change it and the
  /// way out is another bank (PIL-235, same shape as jadwal).
  Widget _buildError(BuildContext context, Object? error) {
    final apiError = error is NasabahApiException ? error : null;
    final choices = widget.onSelect == null
        ? const <MembershipChoice>[]
        : apiError?.choices;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(apiError?.message ?? 'Data gagal dimuat. Silakan coba lagi.'),
          for (final choice in choices ?? const <MembershipChoice>[])
            TextButton(
                onPressed: () => widget.onSelect!(choice.id),
                child: Text(choice.bankName)),
          if (apiError?.statusCode == 403)
            TextButton(
              onPressed: () => context.push(ApprovalBankSampahListPage.route),
              child: const Text('Bank sampah saya'),
            )
          else
            TextButton(onPressed: reload, child: const Text('Coba lagi')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) return _buildError(context, snapshot.error);
          return widget.builder(context, snapshot.data as T);
        },
      );
}

String nasabahRupiah(String amount) {
  final parts = amount.split('.');
  final whole = CurrencyFormatter.formatNumber(int.tryParse(parts.first) ?? 0);
  return 'Rp $whole${parts.length > 1 && parts[1] != '00' ? ',${parts[1]}' : ''}';
}

String nasabahDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class NasabahActivityList extends StatelessWidget {
  const NasabahActivityList({
    super.key,
    required this.activities,
    this.onTap,
  });

  final List<NasabahActivity> activities;
  final ValueChanged<NasabahActivity>? onTap;

  @override
  Widget build(BuildContext context) => activities.isEmpty
      ? const NasabahCard(
          child: Center(child: Text('Belum ada aktivitas.')),
        )
      : Column(
          children: [
            for (final item in activities)
              NasabahActivityCard(
                title: switch (item.type.toLowerCase()) {
                  'setoran' => 'Setoran',
                  'pencairan' => 'Pencairan',
                  _ => item.type,
                },
                date: item.date,
                amount: nasabahRupiah(item.amount),
                isWithdrawal: item.type.toLowerCase() == 'pencairan',
                onTap: onTap == null ? null : () => onTap!(item),
              ),
          ],
        );
}
