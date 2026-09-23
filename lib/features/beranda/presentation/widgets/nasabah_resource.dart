import 'package:flutter/material.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';

/// Owns one request. Re-key on session/selection changes to discard stale data.
class NasabahResource<T> extends StatefulWidget {
  const NasabahResource(
      {super.key, required this.load, required this.builder, this.onSelect});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;
  final ValueChanged<String>? onSelect;
  @override
  State<NasabahResource<T>> createState() => _NasabahResourceState<T>();
}

class _NasabahResourceState<T> extends State<NasabahResource<T>> {
  late Future<T> _request;
  @override
  void initState() {
    super.initState();
    _request = widget.load();
  }

  void _reload() => setState(() {
        _request = widget.load();
      });
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
                        onPressed: _reload, child: const Text('Coba lagi')),
                  ],
                ));
          }
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh))),
            widget.builder(context, snapshot.data as T),
          ]);
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
      ? const Padding(
          padding: EdgeInsets.all(16), child: Text('Belum ada aktivitas.'))
      : Column(children: [
          for (final item in activities)
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(item.type == 'setoran' ? 'Setoran' : item.type),
              subtitle: Text(nasabahDate(item.date)),
              trailing: Text(nasabahRupiah(item.amount)),
            )
        ]);
}
