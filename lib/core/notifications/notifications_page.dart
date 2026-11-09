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
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Notifikasi gagal dimuat.'),
                  TextButton(
                      onPressed: () =>
                          setState(() => _notifications = widget.load()),
                      child: const Text('Coba lagi')),
                ]));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(child: Text('Belum ada notifikasi.'));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(item['title'] as String),
                    subtitle: Text(item['body'] as String),
                    leading: Icon(item['read_at'] == null
                        ? Icons.mark_email_unread_outlined
                        : Icons.mark_email_read_outlined),
                    onTap: item['read_at'] != null
                        ? null
                        : () async {
                            try {
                              await widget.markRead(item['id'] as int);
                              if (mounted) {
                                setState(() => _notifications = widget.load());
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Notifikasi belum dapat ditandai dibaca.')));
                              }
                            }
                          },
                  );
                },
              );
            },
          )),
        ])),
      );
}
