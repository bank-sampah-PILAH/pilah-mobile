import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/colors.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
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
  const NasabahActivityList({super.key, required this.activities});
  final List<NasabahActivity> activities;

  @override
  Widget build(BuildContext context) => activities.isEmpty
      ? const NasabahCard(
          child: Center(child: Text('Belum ada aktivitas.')),
        )
      : Column(children: [
          for (final item in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NasabahCard(
                padding: 12,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.greenLight,
                      child: Icon(
                        item.type.toLowerCase() == 'pencairan'
                            ? Icons.south_west
                            : Icons.recycling_outlined,
                        size: 18,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activityTitle(item.type),
                            style: NasabahStyle.text(
                              14,
                              weight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${nasabahDate(item.date)} · ${_time(item.date)}',
                            style: NasabahStyle.text(
                              12,
                              color: NasabahStyle.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.type.toLowerCase() == 'pencairan' ? '− ' : '+ '}${nasabahRupiah(item.amount)}',
                      style: NasabahStyle.text(
                        13,
                        weight: FontWeight.w600,
                        color: item.type.toLowerCase() == 'pencairan'
                            ? Colors.red.shade700
                            : AppColors.greenDark,
                        tabularFigures: true,
                      ),
                    ),
                  ],
                ),
              ),
            )
        ]);
}

String _activityTitle(String type) => switch (type.toLowerCase()) {
      'setoran' => 'Setoran',
      'pencairan' => 'Pencairan tunai',
      _ => type,
    };

String _time(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}.${local.minute.toString().padLeft(2, '0')}';
}
