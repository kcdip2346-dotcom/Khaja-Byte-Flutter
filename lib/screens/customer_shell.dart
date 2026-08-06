import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../theme.dart';
import 'bookings_screen.dart';
import 'customer_home.dart';
import 'feedback_screen.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  int _unreadNotifs = 0;
  Timer? _pollTimer;
  String _lastStatus = '';

  final _screens = [
    const CustomerHome(),
    const MenuScreen(),
    const BookingsScreen(),
    const FeedbackScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollOrderStatus());
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
        setState(() => _unreadNotifs = (data['unread'] as int? ?? 0));
      }
    } catch (_) {}
  }

  Future<void> _pollOrderStatus() async {
    try {
      final bookings = await Api.getBookings();
      if (bookings.isEmpty) return;
      final latest = bookings.first;
      if (_lastStatus.isNotEmpty && _lastStatus != latest.status) {
        if (latest.status == 'completed') {
          _showOrderReadyDialog(latest.id, latest.itemSummary);
        }
      }
      _lastStatus = latest.status;
    } catch (_) {}
  }

  void _showOrderReadyDialog(int bookingId, String items) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: KbColors.greenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_circle_rounded, color: KbColors.green, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Order Ready! 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text('Your order KB-${bookingId.toString().padLeft(4, '0')} ($items) is ready for pickup!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
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
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Menu'),
          const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Bookings'),
          const NavigationDestination(
              icon: Icon(Icons.feedback_outlined),
              selectedIcon: Icon(Icons.feedback),
              label: 'Feedback'),
          NavigationDestination(
              icon: Badge(
                label: Text('$_unreadNotifs'),
                isLabelVisible: _unreadNotifs > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$_unreadNotifs'),
                isLabelVisible: _unreadNotifs > 0,
                child: const Icon(Icons.notifications),
              ),
              label: 'Alerts'),
        ],
      ),
    );
  }
}
