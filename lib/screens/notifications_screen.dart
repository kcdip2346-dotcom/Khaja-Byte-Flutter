import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'topup_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<Map<String, dynamic>> _data;
  double _balance = 0;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _data = Api.getNotifications();
    _refreshBalance();
    // Live refresh so new alerts appear instantly while viewing
    _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _data = Api.getNotifications());
      _refreshBalance();
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshBalance() async {
    try {
      final credits = await Api.getCredits();
      if (mounted) {
        final bal = (credits['balance'] as num?)?.toDouble();
        if (bal != null && bal != _balance) {
          setState(() => _balance = bal);
        }
      }
    } catch (_) {}
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
              title: const Text('Credits & Alerts'),
              backgroundColor: KbColors.orange800,
              foregroundColor: Colors.white,
            ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snap) {
          final notifs = (snap.data?['notifications'] as List<dynamic>? ?? []);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Credits balance + topup shortcut
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [KbColors.orange800, KbColors.orange600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Text('Credits Balance',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(npr(_balance),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                        'Top up your credits to pay for orders instantly.',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => TopupScreen(
                                    onBalanceChanged: _refreshBalance))),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_card, size: 18),
                        label: const Text('Top up credits',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Notifications',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (notifs.isEmpty)
                const EmptyState(
                    emoji: '🔔', text: 'No notifications yet.')
              else
                ...notifs.map((n) {
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
                                    : n['title']
                                            .toString()
                                            .contains('Cancelled')
                                        ? KbColors.redBg
                                        : KbColors.orange200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                n['title'].toString().contains('Ready')
                                    ? Icons.check_circle_rounded
                                    : n['title']
                                            .toString()
                                            .contains('Cancelled')
                                        ? Icons.cancel_rounded
                                        : Icons.notifications_rounded,
                                size: 20,
                                color: n['title'].toString().contains('Ready')
                                    ? KbColors.green
                                    : n['title']
                                            .toString()
                                            .contains('Cancelled')
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
                                          fontSize: 11,
                                          color: KbColors.inkFaint)),
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
                }),
            ],
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
