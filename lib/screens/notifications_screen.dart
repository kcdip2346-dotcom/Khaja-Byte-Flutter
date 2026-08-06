import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

class NotificationsScreen extends StatefulWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _data = Api.getNotifications();
  }

  Future<void> _markRead(int id) async {
    await Api.markNotificationRead(id);
    setState(() => _data = Api.getNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Notifications'),
              backgroundColor: KbColors.orange800,
              foregroundColor: Colors.white,
            ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: KbColors.orange600));
          }
          final notifs = (snap.data?['notifications'] as List<dynamic>? ?? []);
          if (notifs.isEmpty) {
            return const EmptyState(emoji: '🔔', text: 'No notifications yet.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = notifs[i];
              final read = (n['read'] ?? 0) == 1;
              return Card(
                color: read ? null : KbColors.ivory100,
                child: InkWell(
                  onTap: () {
                    if (!read) _markRead(n['id'] as int);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: n['title'].toString().contains('Ready')
                                ? KbColors.greenBg
                                : n['title'].toString().contains('Cancelled')
                                    ? KbColors.redBg
                                    : KbColors.orange200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            n['title'].toString().contains('Ready')
                                ? Icons.check_circle_rounded
                                : n['title'].toString().contains('Cancelled')
                                    ? Icons.cancel_rounded
                                    : Icons.notifications_rounded,
                            size: 20,
                            color: n['title'].toString().contains('Ready')
                                ? KbColors.green
                                : n['title'].toString().contains('Cancelled')
                                    ? KbColors.red
                                    : KbColors.orange700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title'] as String,
                                  style: TextStyle(
                                      fontWeight: read
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                      fontSize: 13.5)),
                              const SizedBox(height: 3),
                              Text(n['body'] as String,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: KbColors.inkSoft,
                                      height: 1.4)),
                              const SizedBox(height: 6),
                              Text(n['created_at'] as String,
                                  style: const TextStyle(
                                      fontSize: 11, color: KbColors.inkFaint)),
                            ],
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: KbColors.orange600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    if (widget.embedded) {
      return scaffold;
    }
    return scaffold;
  }
}
