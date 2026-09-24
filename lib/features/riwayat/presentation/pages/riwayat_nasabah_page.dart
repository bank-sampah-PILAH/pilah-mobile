import 'package:flutter/material.dart';
import 'package:pilah_mobile/design/constants/nasabah_style.dart';
import 'package:pilah_mobile/features/beranda/data/nasabah_repository.dart';
import 'package:pilah_mobile/features/beranda/presentation/widgets/nasabah_resource.dart';

typedef HistoryLoader = Future<NasabahHistory> Function(int page);

class RiwayatNasabahPage extends StatefulWidget {
  const RiwayatNasabahPage({super.key, required this.loadPage});

  final HistoryLoader loadPage;

  @override
  State<RiwayatNasabahPage> createState() => _RiwayatNasabahPageState();
}

class _RiwayatNasabahPageState extends State<RiwayatNasabahPage> {
  final _activities = <NasabahActivity>[];
  int _page = 0;
  bool _loading = false;
  bool _hasNext = false;
  bool _retryReset = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _retryReset = reset;
    });
    final requestedPage = reset ? 1 : _page + 1;
    try {
      final response = await widget.loadPage(requestedPage);
      if (!mounted) return;
      setState(() {
        if (reset) _activities.clear();
        final knownIds = _activities.map((activity) => activity.id).toSet();
        _activities
            .addAll(response.activities.where((item) => knownIds.add(item.id)));
        _page = requestedPage;
        _hasNext = response.hasNext;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is NasabahApiException
            ? error.message
            : 'Riwayat gagal dimuat. Periksa koneksi dan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: NasabahStyle.maxWidth),
          child: RefreshIndicator(
            onRefresh: () => _load(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  const Expanded(
                      child: Text('Riwayat Aktivitas',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(
                      tooltip: 'Muat ulang',
                      onPressed: _loading ? null : () => _load(reset: true),
                      icon: const Icon(Icons.refresh)),
                ]),
                if (_activities.isNotEmpty)
                  NasabahActivityList(activities: _activities),
                if (_loading)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()))
                else if (_error != null) ...[
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                      onPressed: () => _load(reset: _retryReset),
                      child: const Text('Coba Lagi')),
                ] else if (_activities.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada aktivitas',
                          textAlign: TextAlign.center)),
                if (!_loading && _error == null && _hasNext)
                  OutlinedButton(
                      onPressed: () => _load(), child: const Text('Muat Lagi')),
              ],
            ),
          ),
        ),
      );
}
