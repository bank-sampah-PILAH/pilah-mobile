import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/bases/widgets/app_notification.dart';
import 'package:pilah_mobile/core/bases/widgets/empty_view.dart';
import 'package:pilah_mobile/core/bases/widgets/skeleton_list_item.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/services/di.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.loadPage,
    required this.markRead,
  });

  final Future<Map<String, dynamic>> Function(int page) loadPage;
  final Future<void> Function(int) markRead;

  static const _pageSize = 20;

  static void open(BuildContext context) {
    final network = di<NetworkService>();
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
              loadPage: (page) async =>
                  (await network.get('/api/v1/notifications/', queryParams: {
                'page': page,
                'page_size': _pageSize,
              }))
                      .data as Map<String, dynamic>,
              markRead: (id) async {
                await network.post('/api/v1/notifications/$id/read/');
              },
            )));
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _items = <Map<String, dynamic>>[];
  bool _initialLoading = true;
  bool _initialError = false;
  bool _hasNext = false;
  int _nextPage = 2;
  bool _loadingMore = false;
  bool _pageError = false;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Column(children: [
          const AppBackHeader(title: 'Notifikasi'),
          Expanded(child: _buildContent()),
        ])),
      );

  Widget _buildContent() {
    if (_initialError) return _buildError();
    if (_initialLoading) {
      return ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => const SkeletonListItem(),
      );
    }
    if (_items.isEmpty) {
      return const EmptyView(title: 'Belum ada notifikasi.');
    }
    final itemCount = _items.length + (_hasNext || _pageError ? 1 : 0);
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) => index < _items.length
          ? _buildNotification(_items[index])
          : _buildLoadMore(),
    );
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Notifikasi gagal dimuat.'),
          TextButton(onPressed: _loadFirstPage, child: const Text('Coba lagi')),
        ]),
      );

  Widget _buildLoadMore() {
    if (_loadingMore) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Semantics(
            label: 'Memuat notifikasi berikutnya',
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return Column(children: [
      if (_pageError) const Text('Notifikasi berikutnya gagal dimuat.'),
      TextButton(
        onPressed: _loadMore,
        child: Text(_pageError ? 'Coba lagi' : 'Muat Lagi'),
      ),
    ]);
  }

  Widget _buildNotification(Map<String, dynamic> item) => ListTile(
        title: Text(item['title'] as String),
        subtitle: Text(item['body'] as String),
        leading: Icon(item['read_at'] == null
            ? Icons.mark_email_unread_outlined
            : Icons.mark_email_read_outlined),
        onTap: item['read_at'] != null
            ? null
            : () => _markRead(context, item['id'] as int),
      );

  List<Map<String, dynamic>> _results(Map<String, dynamic> response) =>
      (response['results'] as List<dynamic>).cast<Map<String, dynamic>>();

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _initialError = false;
      _items.clear();
      _hasNext = false;
      _nextPage = 2;
      _pageError = false;
    });
    try {
      final response = await widget.loadPage(1);
      if (!mounted) return;
      setState(() {
        _items.addAll(_results(response));
        _hasNext = response['next'] != null;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialError = true;
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    final page = _nextPage;
    setState(() {
      _loadingMore = true;
      _pageError = false;
    });
    try {
      final response = await widget.loadPage(page);
      if (!mounted) return;
      setState(() {
        final ids = _items.map((item) => item['id']).toSet();
        _items.addAll(_results(response).where((item) => ids.add(item['id'])));
        _hasNext = response['next'] != null;
        _nextPage = page + 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _pageError = true;
      });
    }
  }

  Future<void> _markRead(BuildContext context, int id) async {
    try {
      await widget.markRead(id);
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((item) => item['id'] == id);
        if (index >= 0) {
          _items[index]['read_at'] = DateTime.now().toIso8601String();
        }
      });
    } catch (_) {
      if (context.mounted) {
        AppNotification.showError(
          context,
          title: 'Gagal',
          message: 'Notifikasi belum dapat ditandai dibaca.',
        );
      }
    }
  }
}
