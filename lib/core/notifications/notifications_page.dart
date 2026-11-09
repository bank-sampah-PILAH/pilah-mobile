import 'package:flutter/material.dart';
import 'package:pilah_mobile/core/client/network_service.dart';
import 'package:pilah_mobile/design/widgets/app_back_header.dart';
import 'package:pilah_mobile/services/di.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage(
      {super.key, required this.load, required this.markRead});

  final Future<List<dynamic>> Function() load;
  final Future<void> Function(int) markRead;

  static void open(BuildContext context) {
    final network = di<NetworkService>();
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
              load: () async => (await network.get('/api/v1/notifications/'))
                  .data as List<dynamic>,
              markRead: (id) async {
                await network.post('/api/v1/notifications/$id/read/');
              },
            )));
  }

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Column(children: [
          const AppBackHeader(title: 'Notifikasi'),
          Expanded(
              child: FutureBuilder<List<dynamic>>(
            future: _notifications,
            builder: _buildContent,
          )),
        ])),
      );

  Widget _buildContent(
      BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
    if (snapshot.hasError) return _buildError();
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = snapshot.data!;
    if (items.isEmpty) {
      return const Center(child: Text('Belum ada notifikasi.'));
    }
    return _buildNotifications(items);
  }

  Widget _buildError() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Notifikasi gagal dimuat.'),
          TextButton(onPressed: _reload, child: const Text('Coba lagi')),
        ]),
      );

  Widget _buildNotifications(List<dynamic> items) => ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) =>
            _buildNotification(items[index] as Map<String, dynamic>),
      );

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

  void _reload() {
    setState(() {
      _notifications = widget.load();
    });
  }

  Future<void> _markRead(BuildContext context, int id) async {
    try {
      await widget.markRead(id);
      if (mounted) _reload();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Notifikasi belum dapat ditandai dibaca.')));
      }
    }
  }
}
