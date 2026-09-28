import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/widgets/nasabah_activity_card.dart';
import 'package:pilah_mobile/design/widgets/nasabah_card.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

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
      this.registerReload});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final ValueChanged<String>? onSelect;
  final void Function(Future<void> Function() reload)? registerReload;
  @override
  State<NasabahResource<T>> createState() => NasabahResourceState<T>();
}

class NasabahResourceState<T> extends State<NasabahResource<T>> {
  late Future<T> _request;
  @override
  void initState() {
    super.initState();
    _request = widget.load();
    widget.registerReload?.call(reload);
  }

  /// Reloads and returns a future that settles once the new request does, so
  /// a caller (typically a page-level `RefreshIndicator.onRefresh`) can await
  /// it and keep its spinner up for the right duration.
  Future<void> reload() {
    final future = widget.load();
    setState(() {
      _request = future;
    });
    return future;
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
          if (snapshot.hasError) {
            final error = snapshot.error;
            final apiError = error is NasabahApiException ? error : null;
            return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(apiError?.message ??
                        'Data gagal dimuat. Silakan coba lagi.'),
                    if (widget.onSelect != null)
                      for (final choice
                          in apiError?.choices ?? <MembershipChoice>[])
                        TextButton(
                            onPressed: () => widget.onSelect!(choice.id),
                            child: Text(choice.bankName)),
                    TextButton(
                        onPressed: reload, child: const Text('Coba lagi')),
                  ],
                ));
          }
          return widget.builder(context, snapshot.data as T);
        },
      );
}

String nasabahRupiah(String amount) {
  final parts = amount.split('.');
  final whole = parts.first
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
