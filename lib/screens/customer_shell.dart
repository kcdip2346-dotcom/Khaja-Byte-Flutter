import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'bookings_screen.dart';
import 'customer_home.dart';
import 'feedback_screen.dart';
import 'menu_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  int _unreadNotifs = 0;
  int _lastUnread = 0;
  Timer? _pollTimer;
  final Map<int, String> _statusMap = {};
  final _bookingsKey = GlobalKey<BookingsScreenState>();

  List<Widget> get _screens => [
        CustomerHome(
          unreadNotifs: _unreadNotifs,
          onOpenAlerts: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NotificationsScreen())),
        ),
        const MenuScreen(),
        BookingsScreen(key: _bookingsKey),
        const FeedbackScreen(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollOrderStatus();
      _pollNotifications();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await Api.getNotifications();
      if (mounted) {
        setState(() {
          _unreadNotifs = data['unread'] as int? ?? 0;
          _lastUnread = _unreadNotifs;
        });
      }
    } catch (_) {}
  }

  Future<void> _pollNotifications() async {
    try {
      final data = await Api.getNotifications();
      if (!mounted) return;
      final unread = data['unread'] as int? ?? 0;
      final fresh = (data['notifications'] as List<dynamic>? ?? [])
          .where((n) => (n['read'] ?? 0) != 1)
          .toList();
      if (unread > _lastUnread && fresh.isNotEmpty) {
        final n = fresh.first;
        showTopToast(context, '${n['title']} — ${n['body']}',
            icon: Icons.notifications_active_rounded,
            color: KbColors.orange700);
        setState(() => _unreadNotifs = unread);
      } else if (unread != _unreadNotifs) {
        setState(() => _unreadNotifs = unread);
      }
      _lastUnread = unread;
    } catch (_) {}
  }

  Future<void> _pollOrderStatus() async {
    try {
      final bookings = await Api.getBookings();
      if (bookings.isEmpty) return;
      // Only touch the UI when something actually changed, so the Bookings
      // list doesn't rebuild on every 2s poll.
      bool changed = false;
      for (final b in bookings) {
        if (b.status == 'pending' || b.status == 'completed' ||
            b.status == 'cancelled' || b.status == 'confirmed') {
          final prev = _statusMap[b.id];
          if (prev == null) {
            changed = true; // a new booking appeared
          } else if (prev != b.status) {
            _onStatusChange(b);
            changed = true;
          }
          _statusMap[b.id] = b.status;
        }
      }
      if (changed) _bookingsKey.currentState?.reload();
    } catch (_) {}
  }

  void _onStatusChange(Booking b) {
    switch (b.status) {
      case 'confirmed':
        showTopToast(
          context,
          '${kbRef(b.id)} confirmed — ${b.itemSummary}. '
              'Ready in ~${b.totalTime} min (${b.queueWait} min queue).',
          icon: Icons.check_circle_rounded,
          color: KbColors.blue,
          durationMs: 3200,
        );
        break;
      case 'completed':
        showTopToast(
          context,
          '${kbRef(b.id)} is ready for pickup! ${b.itemSummary}',
          icon: Icons.celebration_rounded,
          color: KbColors.green,
          durationMs: 3800,
        );
        break;
      case 'cancelled':
        showTopToast(
          context,
          '${kbRef(b.id)} was cancelled. Credits will be refunded.',
          icon: Icons.cancel_rounded,
          color: KbColors.red,
        );
        break;
    }
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: IndexedStack(index: _index, children: _screens),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menu'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.feedback_outlined),
              selectedIcon: Icon(Icons.feedback),
              label: 'Feedback'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
